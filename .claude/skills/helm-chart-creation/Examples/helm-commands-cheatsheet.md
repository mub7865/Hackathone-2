# Helm Commands Cheatsheet

Quick reference for all commonly used Helm commands.

## Installation & Setup

```bash
# Check Helm version
helm version

# Add official stable repo
helm repo add stable https://charts.helm.sh/stable

# Add Bitnami repo (popular charts)
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update repos
helm repo update

# List repos
helm repo list

# Remove repo
helm repo remove stable
```

## Creating Charts

```bash
# Create new chart
helm create my-chart

# Create chart structure:
# my-chart/
# ├── Chart.yaml
# ├── values.yaml
# ├── charts/
# └── templates/
```

## Development & Testing

```bash
# Lint chart (check for errors)
helm lint ./my-chart

# Lint with values file
helm lint ./my-chart -f custom-values.yaml

# Template locally (render without install)
helm template my-release ./my-chart

# Template with custom values
helm template my-release ./my-chart -f values-prod.yaml

# Template specific file
helm template my-release ./my-chart -s templates/deployment.yaml

# Dry run (validate against cluster)
helm install my-release ./my-chart --dry-run

# Dry run with debug output
helm install my-release ./my-chart --dry-run --debug

# Show generated manifests
helm get manifest my-release
```

## Installing Charts

```bash
# Install from local chart
helm install my-release ./my-chart

# Install from repo
helm install my-release bitnami/nginx

# Install in namespace
helm install my-release ./my-chart -n my-namespace

# Install and create namespace
helm install my-release ./my-chart -n my-namespace --create-namespace

# Install with custom values file
helm install my-release ./my-chart -f custom-values.yaml

# Install with multiple values files (later overrides earlier)
helm install my-release ./my-chart -f values.yaml -f values-prod.yaml

# Install with inline value overrides
helm install my-release ./my-chart --set replicaCount=3

# Install with multiple inline overrides
helm install my-release ./my-chart \
  --set backend.replicaCount=3 \
  --set frontend.replicaCount=2 \
  --set secrets.dbUrl="postgresql://..."

# Install with set-string (force string type)
helm install my-release ./my-chart --set-string version="1.0"

# Install specific version
helm install my-release bitnami/nginx --version 13.2.0

# Wait for pods to be ready
helm install my-release ./my-chart --wait

# Set timeout
helm install my-release ./my-chart --wait --timeout 5m

# Generate release name
helm install ./my-chart --generate-name

# Atomic install (rollback on failure)
helm install my-release ./my-chart --atomic
```

## Upgrading Releases

```bash
# Upgrade release
helm upgrade my-release ./my-chart

# Upgrade with custom values
helm upgrade my-release ./my-chart -f values-prod.yaml

# Upgrade with inline overrides
helm upgrade my-release ./my-chart --set image.tag=v2

# Install or upgrade (idempotent)
helm upgrade --install my-release ./my-chart

# Upgrade and reuse values
helm upgrade my-release ./my-chart --reuse-values

# Upgrade and reset values to default
helm upgrade my-release ./my-chart --reset-values

# Atomic upgrade (rollback on failure)
helm upgrade my-release ./my-chart --atomic

# Wait for upgrade
helm upgrade my-release ./my-chart --wait

# Force resource update
helm upgrade my-release ./my-chart --force
```

## Managing Releases

```bash
# List releases
helm list

# List releases in namespace
helm list -n my-namespace

# List all releases (all namespaces)
helm list -A

# List with filter
helm list --filter "my-.*"

# List all states (including failed, pending)
helm list -a

# List only deployed
helm list --deployed

# List only failed
helm list --failed

# Get release status
helm status my-release

# Get release status in namespace
helm status my-release -n my-namespace

# Get release notes
helm get notes my-release

# Get deployed values
helm get values my-release

# Get all values (including defaults)
helm get values my-release -a

# Get deployed manifests
helm get manifest my-release

# Get hooks
helm get hooks my-release

# Get all info
helm get all my-release
```

## Rollback

```bash
# View release history
helm history my-release

# Rollback to previous revision
helm rollback my-release

# Rollback to specific revision
helm rollback my-release 2

# Rollback with wait
helm rollback my-release 2 --wait

# Dry run rollback
helm rollback my-release 2 --dry-run
```

## Uninstalling

```bash
# Uninstall release
helm uninstall my-release

# Uninstall in namespace
helm uninstall my-release -n my-namespace

# Keep history after uninstall
helm uninstall my-release --keep-history

# Dry run uninstall
helm uninstall my-release --dry-run
```

## Searching

```bash
# Search repo for chart
helm search repo nginx

# Search with versions
helm search repo nginx --versions

# Search hub (Artifact Hub)
helm search hub nginx

# Show chart info
helm show chart bitnami/nginx

# Show chart values
helm show values bitnami/nginx

# Show chart readme
helm show readme bitnami/nginx

# Show all chart info
helm show all bitnami/nginx
```

## Dependencies

```bash
# List dependencies
helm dependency list ./my-chart

# Update dependencies
helm dependency update ./my-chart

# Build dependencies
helm dependency build ./my-chart
```

## Packaging & Publishing

```bash
# Package chart
helm package ./my-chart

# Package with version
helm package ./my-chart --version 1.0.0

# Package with app version
helm package ./my-chart --app-version 2.0.0

# Package to specific directory
helm package ./my-chart -d ./packages

# Create repo index
helm repo index .

# Create repo index with URL
helm repo index . --url https://example.com/charts

# Push to OCI registry
helm push my-chart-1.0.0.tgz oci://registry.example.com/charts
```

## Plugins

```bash
# List plugins
helm plugin list

# Install plugin
helm plugin install https://github.com/databus23/helm-diff

# Update plugin
helm plugin update diff

# Uninstall plugin
helm plugin uninstall diff
```

## Environment Variables

```bash
# Set Helm home directory
export HELM_HOME=~/.helm

# Set default namespace
export HELM_NAMESPACE=my-namespace

# Set kubeconfig
export KUBECONFIG=~/.kube/config

# Debug mode
export HELM_DEBUG=1
```

## Quick Reference Table

| Action | Command |
|--------|---------|
| Create chart | `helm create <name>` |
| Install | `helm install <release> <chart>` |
| Upgrade | `helm upgrade <release> <chart>` |
| Install/Upgrade | `helm upgrade --install <release> <chart>` |
| List releases | `helm list` |
| Status | `helm status <release>` |
| History | `helm history <release>` |
| Rollback | `helm rollback <release> <revision>` |
| Uninstall | `helm uninstall <release>` |
| Lint | `helm lint <chart>` |
| Template | `helm template <release> <chart>` |
| Dry run | `helm install <release> <chart> --dry-run` |
| Get values | `helm get values <release>` |
| Search | `helm search repo <keyword>` |
| Package | `helm package <chart>` |

## Common Flags

| Flag | Description |
|------|-------------|
| `-n, --namespace` | Kubernetes namespace |
| `-f, --values` | Values file |
| `--set` | Set values on command line |
| `--dry-run` | Simulate installation |
| `--debug` | Enable debug output |
| `--wait` | Wait for resources to be ready |
| `--timeout` | Time to wait |
| `--atomic` | Rollback on failure |
| `-o, --output` | Output format (table/json/yaml) |

## Useful Aliases

Add to `~/.bashrc` or `~/.zshrc`:

```bash
alias h='helm'
alias hi='helm install'
alias hu='helm upgrade'
alias hui='helm upgrade --install'
alias hl='helm list'
alias hs='helm status'
alias hh='helm history'
alias hr='helm rollback'
alias hun='helm uninstall'
alias ht='helm template'
alias hd='helm install --dry-run --debug'
```
