# Troubleshooting Kubernetes Networking Issues

This guide covers common networking issues in Kubernetes.

## Table of Contents

1. [Service Discovery Issues](#service-discovery-issues)
2. [DNS Issues](#dns-issues)
3. [Ingress Issues](#ingress-issues)
4. [Network Policy Issues](#network-policy-issues)
5. [Pod-to-Pod Communication](#pod-to-pod-communication)

---

## Service Discovery Issues

### Issue 1: Cannot Resolve Service Name

**Symptoms:**
- DNS lookup fails for service name
- `nslookup` or `dig` returns NXDOMAIN
- Application cannot connect to service

**Diagnosis:**

```bash
# Test DNS from a pod
kubectl run test-dns --image=busybox:1.36 --rm -it --restart=Never -- \
  nslookup <service-name>.<namespace>.svc.cluster.local

# Check DNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl get pods -n kube-system -l k8s-app=coredns

# Check DNS service
kubectl get service -n kube-system kube-dns
```

**Common Causes and Solutions:**

#### Cause 1: Service Does Not Exist

**Solution:** Create the service

```bash
# Check if service exists
kubectl get service <service-name> -n <namespace>

# If not, create it
kubectl apply -f service.yaml
```

#### Cause 2: Wrong Service Name

**Solution:** Use correct FQDN

```bash
# Within same namespace
curl http://<service-name>

# From different namespace
curl http://<service-name>.<namespace>.svc.cluster.local

# Full FQDN
curl http://<service-name>.<namespace>.svc.cluster.local
```

#### Cause 3: DNS Not Working

**Solution:** Fix DNS (see DNS Issues below)

---

### Issue 2: Service Endpoints Empty

**Symptoms:**
- Service exists but has no endpoints
- Connections to service fail
- `kubectl get endpoints` shows no addresses

**Diagnosis:**

```bash
# Check service endpoints
kubectl get endpoints <service-name> -n <namespace>

# Describe service
kubectl describe service <service-name> -n <namespace>

# Check pod labels
kubectl get pods -n <namespace> --show-labels
```

**Common Causes and Solutions:**

#### Cause 1: Selector Mismatch

**Solution:** Fix service selector to match pod labels

```yaml
# Service selector
spec:
  selector:
    app: backend
    version: v1

# Pod labels (must match)
metadata:
  labels:
    app: backend
    version: v1
```

#### Cause 2: No Ready Pods

**Solution:** Fix pod readiness issues

```bash
# Check pod status
kubectl get pods -n <namespace> -l app=<app-name>

# Pods must be Running and Ready (1/1)
# If not ready, check readiness probe
kubectl describe pod <pod-name> -n <namespace>
```

#### Cause 3: Wrong Namespace

**Solution:** Ensure service and pods are in same namespace

```bash
# Check service namespace
kubectl get service <service-name> --all-namespaces

# Check pod namespace
kubectl get pods -l app=<app-name> --all-namespaces
```

---

## DNS Issues

### Issue 1: DNS Resolution Fails

**Symptoms:**
- Cannot resolve any service names
- DNS queries timeout
- Application cannot connect to services

**Diagnosis:**

```bash
# Test DNS resolution
kubectl run test-dns --image=busybox:1.36 --rm -it --restart=Never -- \
  nslookup kubernetes.default

# Check DNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl get pods -n kube-system -l k8s-app=coredns

# Check DNS logs
kubectl logs -n kube-system -l k8s-app=coredns --tail=50

# Check DNS service
kubectl get service -n kube-system kube-dns
```

**Common Causes and Solutions:**

#### Cause 1: DNS Pods Not Running

**Solution:** Restart DNS pods

```bash
# Check DNS pod status
kubectl get pods -n kube-system -l k8s-app=coredns

# If not running, delete pods (they will be recreated)
kubectl delete pods -n kube-system -l k8s-app=coredns

# Wait for new pods to start
kubectl get pods -n kube-system -l k8s-app=coredns --watch
```

#### Cause 2: DNS Service Not Accessible

**Solution:** Check DNS service configuration

```bash
# Check DNS service
kubectl get service -n kube-system kube-dns

# Should have ClusterIP (usually 10.96.0.10)
# Check if service has endpoints
kubectl get endpoints -n kube-system kube-dns
```

#### Cause 3: Network Policy Blocking DNS

**Solution:** Allow DNS traffic in network policy

```yaml
# Allow DNS egress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: <namespace>
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  # Allow DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
```

#### Cause 4: Incorrect DNS Configuration

**Solution:** Check pod DNS configuration

```bash
# Check DNS config in pod
kubectl exec <pod-name> -n <namespace> -- cat /etc/resolv.conf

# Should contain:
# nameserver 10.96.0.10  (or your cluster DNS IP)
# search <namespace>.svc.cluster.local svc.cluster.local cluster.local
```

---

### Issue 2: Slow DNS Resolution

**Symptoms:**
- DNS queries take long time
- Application slow to start
- Intermittent connection issues

**Diagnosis:**

```bash
# Test DNS resolution time
kubectl run test-dns --image=busybox:1.36 --rm -it --restart=Never -- \
  time nslookup kubernetes.default

# Check DNS pod resource usage
kubectl top pods -n kube-system -l k8s-app=coredns

# Check DNS logs for errors
kubectl logs -n kube-system -l k8s-app=coredns --tail=100
```

**Solutions:**

#### Solution 1: Scale DNS Pods

```bash
# Check current DNS replicas
kubectl get deployment -n kube-system coredns

# Scale up DNS pods
kubectl scale deployment coredns -n kube-system --replicas=3
```

#### Solution 2: Increase DNS Cache

```yaml
# Edit CoreDNS ConfigMap
kubectl edit configmap coredns -n kube-system

# Add cache plugin
.:53 {
    cache 30  # Cache for 30 seconds
    errors
    health
    kubernetes cluster.local in-addr.arpa ip6.arpa {
        pods insecure
        fallthrough in-addr.arpa ip6.arpa
    }
    forward . /etc/resolv.conf
    reload
}
```

#### Solution 3: Use NodeLocal DNSCache

```bash
# Install NodeLocal DNSCache
kubectl apply -f https://k8s.io/examples/admin/dns/nodelocaldns.yaml

# This creates a DNS cache on each node
```

---

## Ingress Issues

### Issue 1: Ingress Not Working

**Symptoms:**
- Cannot access application via ingress URL
- 404 or 503 errors
- Ingress shows no address

**Diagnosis:**

```bash
# Check ingress
kubectl get ingress -n <namespace>

# Describe ingress
kubectl describe ingress <ingress-name> -n <namespace>

# Check ingress controller
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

**Common Causes and Solutions:**

#### Cause 1: Ingress Controller Not Installed

**Solution:** Install ingress controller

```bash
# Install nginx ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# For Minikube
minikube addons enable ingress

# Verify installation
kubectl get pods -n ingress-nginx
```

#### Cause 2: Wrong Ingress Class

**Solution:** Specify correct ingress class

```yaml
# Check available ingress classes
# kubectl get ingressclass

# Specify in ingress
spec:
  ingressClassName: nginx  # or traefik, haproxy, etc.
```

#### Cause 3: Service Not Found

**Solution:** Ensure service exists and is accessible

```bash
# Check if service exists
kubectl get service <service-name> -n <namespace>

# Check service endpoints
kubectl get endpoints <service-name> -n <namespace>

# Test service directly
kubectl run test-pod --image=busybox:1.36 --rm -it --restart=Never -- \
  wget -O- http://<service-name>.<namespace>.svc.cluster.local
```

#### Cause 4: Path Routing Issues

**Solution:** Fix path configuration

```yaml
# Use correct path type
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /api
        pathType: Prefix  # or Exact, ImplementationSpecific
        backend:
          service:
            name: backend-service
            port:
              number: 8000
```

---

### Issue 2: TLS/HTTPS Not Working

**Symptoms:**
- HTTPS connection fails
- Certificate errors
- Redirect loop

**Diagnosis:**

```bash
# Check ingress TLS configuration
kubectl get ingress <ingress-name> -n <namespace> -o yaml

# Check TLS secret
kubectl get secret <tls-secret-name> -n <namespace>

# Describe secret
kubectl describe secret <tls-secret-name> -n <namespace>

# Check cert-manager (if using)
kubectl get certificate -n <namespace>
kubectl describe certificate <cert-name> -n <namespace>
```

**Common Causes and Solutions:**

#### Cause 1: TLS Secret Missing

**Solution:** Create TLS secret

```bash
# Create TLS secret from certificate files
kubectl create secret tls <tls-secret-name> \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key \
  -n <namespace>

# Or use cert-manager to auto-generate
```

#### Cause 2: Certificate Not Valid

**Solution:** Check certificate validity

```bash
# Check certificate expiration
kubectl get secret <tls-secret-name> -n <namespace> -o jsonpath='{.data.tls\.crt}' | \
  base64 -d | openssl x509 -noout -dates

# Check certificate domain
kubectl get secret <tls-secret-name> -n <namespace> -o jsonpath='{.data.tls\.crt}' | \
  base64 -d | openssl x509 -noout -text | grep DNS
```

#### Cause 3: cert-manager Issues

**Solution:** Fix cert-manager configuration

```bash
# Check cert-manager pods
kubectl get pods -n cert-manager

# Check certificate status
kubectl get certificate -n <namespace>

# Describe certificate for events
kubectl describe certificate <cert-name> -n <namespace>

# Check certificate request
kubectl get certificaterequest -n <namespace>
```

---

## Network Policy Issues

### Issue 1: Network Policy Blocking Traffic

**Symptoms:**
- Pods cannot communicate
- Connection timeout
- Previously working connections now fail

**Diagnosis:**

```bash
# Check network policies
kubectl get networkpolicy -n <namespace>

# Describe network policy
kubectl describe networkpolicy <policy-name> -n <namespace>

# Test connectivity
kubectl run test-pod --image=busybox:1.36 --rm -it --restart=Never -- \
  wget -O- http://<service-name>.<namespace>.svc.cluster.local
```

**Common Causes and Solutions:**

#### Cause 1: Deny-All Policy

**Solution:** Add allow rules

```yaml
# Check for deny-all policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress

# Add specific allow rules
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8000
```

#### Cause 2: Missing Egress Rules

**Solution:** Add egress rules

```yaml
# Allow egress to specific services
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Egress
  egress:
  # Allow to backend
  - to:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 8000
  # Allow DNS
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
```

#### Cause 3: Wrong Selector

**Solution:** Fix pod selector

```yaml
# Network policy selector must match pod labels
spec:
  podSelector:
    matchLabels:
      app: backend  # Must match pod labels exactly
```

---

## Pod-to-Pod Communication

### Issue 1: Pods Cannot Communicate

**Symptoms:**
- Connection timeout between pods
- Pods in same namespace cannot reach each other
- Network errors in logs

**Diagnosis:**

```bash
# Get pod IPs
kubectl get pods -n <namespace> -o wide

# Test connectivity from one pod to another
kubectl exec <pod-1> -n <namespace> -- ping <pod-2-ip>
kubectl exec <pod-1> -n <namespace> -- wget -O- http://<pod-2-ip>:8000

# Check network plugin
kubectl get pods -n kube-system | grep -E 'calico|flannel|weave|cilium'
```

**Common Causes and Solutions:**

#### Cause 1: Network Plugin Issues

**Solution:** Check and restart network plugin

```bash
# Check network plugin pods
kubectl get pods -n kube-system -l k8s-app=calico-node
kubectl get pods -n kube-system -l app=flannel

# Check logs
kubectl logs -n kube-system -l k8s-app=calico-node --tail=50

# Restart network plugin pods if needed
kubectl delete pods -n kube-system -l k8s-app=calico-node
```

#### Cause 2: Firewall Rules

**Solution:** Check node firewall rules

```bash
# Check iptables rules on nodes
# SSH to node and run:
# sudo iptables -L -n -v

# Check if pod network is allowed
```

#### Cause 3: CNI Configuration

**Solution:** Verify CNI configuration

```bash
# Check CNI config on nodes
# SSH to node and check:
# ls /etc/cni/net.d/
# cat /etc/cni/net.d/*.conf
```

---

## General Networking Debugging

### Useful Commands

```bash
# Test DNS
kubectl run test-dns --image=busybox:1.36 --rm -it --restart=Never -- \
  nslookup kubernetes.default

# Test service connectivity
kubectl run test-curl --image=curlimages/curl --rm -it --restart=Never -- \
  curl http://<service-name>.<namespace>.svc.cluster.local

# Test external connectivity
kubectl run test-curl --image=curlimages/curl --rm -it --restart=Never -- \
  curl https://www.google.com

# Check pod network
kubectl exec <pod-name> -n <namespace> -- ip addr
kubectl exec <pod-name> -n <namespace> -- ip route

# Check DNS configuration
kubectl exec <pod-name> -n <namespace> -- cat /etc/resolv.conf

# Trace network path
kubectl exec <pod-name> -n <namespace> -- traceroute <destination>

# Check open ports
kubectl exec <pod-name> -n <namespace> -- netstat -tuln
```

### Network Debugging Pod

```yaml
# Deploy a network debugging pod
apiVersion: v1
kind: Pod
metadata:
  name: netshoot
  namespace: default
spec:
  containers:
  - name: netshoot
    image: nicolaka/netshoot
    command: ["sleep", "infinity"]
```

```bash
# Use the debugging pod
kubectl exec -it netshoot -- bash

# Inside the pod, you have access to:
# - curl, wget
# - dig, nslookup
# - ping, traceroute
# - netstat, ss
# - tcpdump
# - iperf3
```

---

## Best Practices

1. **Always test DNS first**: Most networking issues are DNS-related
2. **Check service endpoints**: Ensure services have healthy endpoints
3. **Verify network policies**: Network policies can block traffic
4. **Use FQDN for cross-namespace**: Use full service names across namespaces
5. **Monitor network plugin**: Keep network plugin healthy and updated
6. **Test incrementally**: Test pod → service → ingress step by step
7. **Check logs**: Network plugin and ingress controller logs are valuable
8. **Use debugging pods**: Keep a netshoot pod for troubleshooting
9. **Document network architecture**: Know your network topology
10. **Monitor metrics**: Track network latency and errors
