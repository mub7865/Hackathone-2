# AWS Deployment Troubleshooting

Common issues and solutions when deploying to AWS.

## Table of Contents

1. [ECS/Fargate Issues](#ecsfargate-issues)
2. [Elastic Beanstalk Issues](#elastic-beanstalk-issues)
3. [RDS Issues](#rds-issues)
4. [Load Balancer Issues](#load-balancer-issues)
5. [ECR Issues](#ecr-issues)

---

## ECS/Fargate Issues

### Issue 1: Task Fails to Start

**Symptoms:**
- Task status shows "STOPPED"
- Service cannot maintain desired count
- Tasks exit immediately after starting

**Diagnosis:**

```bash
# Check task status
aws ecs describe-tasks \
  --cluster myapp-cluster \
  --tasks $(aws ecs list-tasks --cluster myapp-cluster --service-name myapp-service --query 'taskArns[0]' --output text)

# Check service events
aws ecs describe-services \
  --cluster myapp-cluster \
  --services myapp-service \
  --query 'services[0].events[0:10]'

# View CloudWatch logs
aws logs tail /ecs/myapp --follow
```

**Common Causes and Solutions:**

#### Cause 1: Image Pull Error

**Solution:** Check ECR permissions and image existence

```bash
# Verify image exists
aws ecr describe-images \
  --repository-name myapp/backend \
  --image-ids imageTag=v1.0.0

# Check task execution role permissions
aws iam get-role-policy \
  --role-name myapp-ecs-execution-role \
  --policy-name ECSTaskExecutionPolicy

# Grant ECR pull permissions
aws iam attach-role-policy \
  --role-name myapp-ecs-execution-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

#### Cause 2: Insufficient Resources

**Solution:** Increase task CPU/memory or check cluster capacity

```bash
# Update task definition with more resources
aws ecs register-task-definition \
  --family myapp-backend \
  --cpu 512 \
  --memory 1024 \
  --container-definitions file://task-def.json

# Update service to use new task definition
aws ecs update-service \
  --cluster myapp-cluster \
  --service myapp-service \
  --task-definition myapp-backend:2
```

#### Cause 3: Application Crash

**Solution:** Check application logs and environment variables

```bash
# View logs with error filter
aws logs filter-log-events \
  --log-group-name /ecs/myapp \
  --filter-pattern "ERROR" \
  --start-time $(date -d '1 hour ago' +%s)000

# Check environment variables in task definition
aws ecs describe-task-definition \
  --task-definition myapp-backend \
  --query 'taskDefinition.containerDefinitions[0].environment'
```

---

### Issue 2: Service Cannot Reach Desired Count

**Symptoms:**
- Service shows fewer tasks than desired
- Tasks keep restarting
- "service myapp-service was unable to place a task" error

**Diagnosis:**

```bash
# Check service status
aws ecs describe-services \
  --cluster myapp-cluster \
  --services myapp-service \
  --query 'services[0].{desired:desiredCount,running:runningCount,pending:pendingCount}'

# Check service events
aws ecs describe-services \
  --cluster myapp-cluster \
  --services myapp-service \
  --query 'services[0].events[0:5]'
```

**Solutions:**

#### Solution 1: Check Subnet Availability

```bash
# Verify subnets have available IPs
aws ec2 describe-subnets \
  --subnet-ids subnet-xxx subnet-yyy \
  --query 'Subnets[*].{SubnetId:SubnetId,AvailableIps:AvailableIpAddressCount}'

# Update service with different subnets
aws ecs update-service \
  --cluster myapp-cluster \
  --service myapp-service \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-aaa,subnet-bbb],securityGroups=[sg-xxx]}"
```

#### Solution 2: Check Security Group Rules

```bash
# Verify security group allows required traffic
aws ec2 describe-security-groups \
  --group-ids sg-xxx \
  --query 'SecurityGroups[0].{Ingress:IpPermissions,Egress:IpPermissionsEgress}'

# Add required ingress rule
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxx \
  --protocol tcp \
  --port 8000 \
  --source-group sg-alb
```

---

### Issue 3: Task Health Check Failures

**Symptoms:**
- Tasks fail health checks
- Load balancer shows unhealthy targets
- Tasks restart frequently

**Diagnosis:**

```bash
# Check target health
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/myapp-tg/xxx

# Check health check configuration
aws elbv2 describe-target-groups \
  --target-group-arns arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/myapp-tg/xxx \
  --query 'TargetGroups[0].HealthCheckPath'
```

**Solutions:**

#### Solution 1: Fix Health Check Path

```bash
# Update health check configuration
aws elbv2 modify-target-group \
  --target-group-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/myapp-tg/xxx \
  --health-check-path /health \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3
```

#### Solution 2: Increase Health Check Grace Period

```bash
# Update service with longer grace period
aws ecs update-service \
  --cluster myapp-cluster \
  --service myapp-service \
  --health-check-grace-period-seconds 300
```

---

## Elastic Beanstalk Issues

### Issue 1: Environment Health is Red

**Symptoms:**
- Environment shows "Severe" or "Degraded" health
- Application not accessible
- 502/503 errors

**Diagnosis:**

```bash
# Check environment health
aws elasticbeanstalk describe-environment-health \
  --environment-name myapp-prod \
  --attribute-names All

# Check recent events
aws elasticbeanstalk describe-events \
  --environment-name myapp-prod \
  --max-records 20
```

**Solutions:**

#### Solution 1: Check Application Logs

```bash
# Retrieve logs
aws elasticbeanstalk retrieve-environment-info \
  --environment-name myapp-prod \
  --info-type tail

# Download logs
aws elasticbeanstalk describe-environment-resources \
  --environment-name myapp-prod
```

#### Solution 2: Restart Application Servers

```bash
# Restart app servers
aws elasticbeanstalk restart-app-server \
  --environment-name myapp-prod
```

---

### Issue 2: Deployment Fails

**Symptoms:**
- Deployment stuck or fails
- New version not deployed
- Rollback occurs

**Diagnosis:**

```bash
# Check deployment status
aws elasticbeanstalk describe-environments \
  --environment-names myapp-prod \
  --query 'Environments[0].Status'

# View deployment events
aws elasticbeanstalk describe-events \
  --environment-name myapp-prod \
  --severity ERROR
```

**Solutions:**

#### Solution 1: Check Application Version

```bash
# List application versions
aws elasticbeanstalk describe-application-versions \
  --application-name myapp

# Deploy specific version
aws elasticbeanstalk update-environment \
  --environment-name myapp-prod \
  --version-label v1.0.0
```

#### Solution 2: Increase Deployment Timeout

```bash
# Update configuration
aws elasticbeanstalk update-environment \
  --environment-name myapp-prod \
  --option-settings Namespace=aws:elasticbeanstalk:command,OptionName=Timeout,Value=600
```

---

## RDS Issues

### Issue 1: Cannot Connect to Database

**Symptoms:**
- Connection timeout
- "could not connect to server" error
- Authentication failed

**Diagnosis:**

```bash
# Check database status
aws rds describe-db-instances \
  --db-instance-identifier myapp-prod-db \
  --query 'DBInstances[0].DBInstanceStatus'

# Check security group
aws rds describe-db-instances \
  --db-instance-identifier myapp-prod-db \
  --query 'DBInstances[0].VpcSecurityGroups'

# Test connectivity from EC2
telnet myapp-prod-db.xxx.us-east-1.rds.amazonaws.com 5432
```

**Solutions:**

#### Solution 1: Update Security Group

```bash
# Get ECS task security group
ECS_SG=$(aws ecs describe-services \
  --cluster myapp-cluster \
  --services myapp-service \
  --query 'services[0].networkConfiguration.awsvpcConfiguration.securityGroups[0]' \
  --output text)

# Allow PostgreSQL from ECS
aws ec2 authorize-security-group-ingress \
  --group-id sg-rds \
  --protocol tcp \
  --port 5432 \
  --source-group $ECS_SG
```

#### Solution 2: Check Database Endpoint

```bash
# Get correct endpoint
aws rds describe-db-instances \
  --db-instance-identifier myapp-prod-db \
  --query 'DBInstances[0].Endpoint.{Address:Address,Port:Port}'
```

---

### Issue 2: Database Performance Issues

**Symptoms:**
- Slow queries
- High CPU usage
- Connection pool exhaustion

**Diagnosis:**

```bash
# Check CPU utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value=myapp-prod-db \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average

# Check database connections
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value=myapp-prod-db \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

**Solutions:**

#### Solution 1: Scale Up Database

```bash
# Modify instance class
aws rds modify-db-instance \
  --db-instance-identifier myapp-prod-db \
  --db-instance-class db.t3.medium \
  --apply-immediately
```

#### Solution 2: Enable Performance Insights

```bash
# Enable Performance Insights
aws rds modify-db-instance \
  --db-instance-identifier myapp-prod-db \
  --enable-performance-insights \
  --performance-insights-retention-period 7
```

---

## Load Balancer Issues

### Issue 1: 502 Bad Gateway Errors

**Symptoms:**
- Intermittent 502 errors
- Load balancer cannot reach targets
- Unhealthy targets

**Diagnosis:**

```bash
# Check target health
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/myapp-tg/xxx

# Check ALB access logs
aws s3 ls s3://my-alb-logs/AWSLogs/123456789012/elasticloadbalancing/us-east-1/
```

**Solutions:**

#### Solution 1: Check Security Groups

```bash
# Verify ALB can reach targets
aws ec2 describe-security-groups \
  --group-ids sg-ecs \
  --query 'SecurityGroups[0].IpPermissions'

# Add rule if missing
aws ec2 authorize-security-group-ingress \
  --group-id sg-ecs \
  --protocol tcp \
  --port 8000 \
  --source-group sg-alb
```

#### Solution 2: Increase Target Deregistration Delay

```bash
# Update deregistration delay
aws elbv2 modify-target-group-attributes \
  --target-group-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/myapp-tg/xxx \
  --attributes Key=deregistration_delay.timeout_seconds,Value=300
```

---

### Issue 2: SSL Certificate Issues

**Symptoms:**
- HTTPS not working
- Certificate errors
- Mixed content warnings

**Diagnosis:**

```bash
# Check listener configuration
aws elbv2 describe-listeners \
  --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/myapp-alb/xxx

# Check certificate
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-1:123456789012:certificate/xxx
```

**Solutions:**

#### Solution 1: Add HTTPS Listener

```bash
# Create HTTPS listener
aws elbv2 create-listener \
  --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/myapp-alb/xxx \
  --protocol HTTPS \
  --port 443 \
  --certificates CertificateArn=arn:aws:acm:us-east-1:123456789012:certificate/xxx \
  --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/myapp-tg/xxx
```

#### Solution 2: Request New Certificate

```bash
# Request ACM certificate
aws acm request-certificate \
  --domain-name myapp.example.com \
  --validation-method DNS \
  --subject-alternative-names www.myapp.example.com
```

---

## ECR Issues

### Issue 1: Cannot Push Images

**Symptoms:**
- "denied: Your authorization token has expired" error
- "no basic auth credentials" error
- Push fails

**Diagnosis:**

```bash
# Check ECR repository
aws ecr describe-repositories \
  --repository-names myapp/backend

# Check authentication
aws ecr get-login-password --region us-east-1
```

**Solutions:**

#### Solution 1: Re-authenticate Docker

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

# Verify login
docker info | grep Registry
```

#### Solution 2: Check IAM Permissions

```bash
# Verify user has ECR permissions
aws iam get-user-policy \
  --user-name myuser \
  --policy-name ECRPushPolicy

# Attach ECR policy if missing
aws iam attach-user-policy \
  --user-name myuser \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
```

---

### Issue 2: Image Scan Findings

**Symptoms:**
- Security vulnerabilities detected
- High/critical severity findings
- Deployment blocked

**Diagnosis:**

```bash
# Check scan results
aws ecr describe-image-scan-findings \
  --repository-name myapp/backend \
  --image-id imageTag=v1.0.0

# List findings by severity
aws ecr describe-image-scan-findings \
  --repository-name myapp/backend \
  --image-id imageTag=v1.0.0 \
  --query 'imageScanFindings.findings[?severity==`CRITICAL`]'
```

**Solutions:**

#### Solution 1: Update Base Image

```dockerfile
# Use updated base image
FROM python:3.13-slim

# Update packages
RUN apt-get update && apt-get upgrade -y
```

#### Solution 2: Configure Scan on Push

```bash
# Enable scan on push
aws ecr put-image-scanning-configuration \
  --repository-name myapp/backend \
  --image-scanning-configuration scanOnPush=true
```

---

## General Debugging Commands

```bash
# View CloudWatch logs
aws logs tail /ecs/myapp --follow --filter-pattern "ERROR"

# Check service quotas
aws service-quotas list-service-quotas \
  --service-code ecs

# View CloudTrail events
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceType,AttributeValue=AWS::ECS::Service \
  --max-results 10

# Check AWS service health
aws health describe-events \
  --filter services=ECS,regions=us-east-1

# Export CloudFormation template
aws cloudformation get-template \
  --stack-name myapp-stack \
  --query TemplateBody \
  --output text > template.yaml
```

---

## Best Practices

1. **Use IAM roles** instead of access keys
2. **Enable CloudWatch Container Insights** for ECS
3. **Set up CloudWatch alarms** for critical metrics
4. **Use private subnets** for ECS tasks and RDS
5. **Enable VPC Flow Logs** for network troubleshooting
6. **Use Secrets Manager** for sensitive data
7. **Implement proper health checks** for all services
8. **Enable ALB access logs** for debugging
9. **Use AWS X-Ray** for distributed tracing
10. **Regular security scans** of container images
