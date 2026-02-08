# AWS Deployment Example

Complete example of deploying a microservices application to AWS using ECS Fargate.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                            AWS Cloud                                 │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                    VPC (10.0.0.0/16)                           │ │
│  │                                                                │ │
│  │  ┌──────────────────────────────────────────────────────────┐ │ │
│  │  │              Public Subnets (2 AZs)                      │ │ │
│  │  │                                                          │ │ │
│  │  │  ┌────────────────────────────────────────────────────┐ │ │ │
│  │  │  │     Application Load Balancer (ALB)               │ │ │ │
│  │  │  │     Port: 80, 443                                  │ │ │ │
│  │  │  └────────────────┬───────────────────────────────────┘ │ │ │
│  │  │                   │                                      │ │ │
│  │  │  ┌────────────────▼───────────────────────────────────┐ │ │ │
│  │  │  │         ECS Fargate Tasks                          │ │ │ │
│  │  │  │                                                    │ │ │ │
│  │  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐        │ │ │ │
│  │  │  │  │ Frontend │  │ Backend  │  │  Worker  │        │ │ │ │
│  │  │  │  │ (Next.js)│  │(FastAPI) │  │ (Celery) │        │ │ │ │
│  │  │  │  └──────────┘  └──────────┘  └──────────┘        │ │ │ │
│  │  │  └────────────────────────────────────────────────────┘ │ │ │
│  │  └──────────────────────────────────────────────────────────┘ │ │
│  │                                                                │ │
│  │  ┌──────────────────────────────────────────────────────────┐ │ │
│  │  │              Private Subnets (2 AZs)                     │ │ │
│  │  │                                                          │ │ │
│  │  │  ┌────────────────┐    ┌────────────────┐              │ │ │
│  │  │  │   RDS          │    │   ElastiCache  │              │ │ │
│  │  │  │   PostgreSQL   │    │   Redis        │              │ │ │
│  │  │  └────────────────┘    └────────────────┘              │ │ │
│  │  └──────────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │      ECR (Elastic Container Registry)                          │ │
│  │      123456789012.dkr.ecr.us-east-1.amazonaws.com             │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │      Secrets Manager (Database credentials, API keys)          │ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure AWS credentials
aws configure
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region name: us-east-1
# Default output format: json

# Install ECS CLI (optional)
sudo curl -Lo /usr/local/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest
sudo chmod +x /usr/local/bin/ecs-cli
```

## Step 1: Create VPC and Networking

```bash
# Create VPC
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=myapp-vpc}]' \
  --query 'Vpc.VpcId' \
  --output text)

echo "VPC ID: $VPC_ID"

# Enable DNS hostnames
aws ec2 modify-vpc-attribute \
  --vpc-id $VPC_ID \
  --enable-dns-hostnames

# Create Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=myapp-igw}]' \
  --query 'InternetGateway.InternetGatewayId' \
  --output text)

# Attach Internet Gateway to VPC
aws ec2 attach-internet-gateway \
  --vpc-id $VPC_ID \
  --internet-gateway-id $IGW_ID

# Create public subnets (2 AZs)
PUBLIC_SUBNET_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=myapp-public-1}]' \
  --query 'Subnet.SubnetId' \
  --output text)

PUBLIC_SUBNET_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.2.0/24 \
  --availability-zone us-east-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=myapp-public-2}]' \
  --query 'Subnet.SubnetId' \
  --output text)

# Create private subnets (2 AZs)
PRIVATE_SUBNET_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.11.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=myapp-private-1}]' \
  --query 'Subnet.SubnetId' \
  --output text)

PRIVATE_SUBNET_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.12.0/24 \
  --availability-zone us-east-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=myapp-private-2}]' \
  --query 'Subnet.SubnetId' \
  --output text)

# Create route table for public subnets
PUBLIC_RT=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=myapp-public-rt}]' \
  --query 'RouteTable.RouteTableId' \
  --output text)

# Add route to Internet Gateway
aws ec2 create-route \
  --route-table-id $PUBLIC_RT \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID

# Associate public subnets with route table
aws ec2 associate-route-table \
  --subnet-id $PUBLIC_SUBNET_1 \
  --route-table-id $PUBLIC_RT

aws ec2 associate-route-table \
  --subnet-id $PUBLIC_SUBNET_2 \
  --route-table-id $PUBLIC_RT
```

## Step 2: Create Security Groups

```bash
# ALB Security Group
ALB_SG=$(aws ec2 create-security-group \
  --group-name myapp-alb-sg \
  --description "Security group for ALB" \
  --vpc-id $VPC_ID \
  --query 'GroupId' \
  --output text)

# Allow HTTP and HTTPS
aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

# ECS Tasks Security Group
ECS_SG=$(aws ec2 create-security-group \
  --group-name myapp-ecs-sg \
  --description "Security group for ECS tasks" \
  --vpc-id $VPC_ID \
  --query 'GroupId' \
  --output text)

# Allow traffic from ALB
aws ec2 authorize-security-group-ingress \
  --group-id $ECS_SG \
  --protocol tcp \
  --port 8000 \
  --source-group $ALB_SG

# RDS Security Group
RDS_SG=$(aws ec2 create-security-group \
  --group-name myapp-rds-sg \
  --description "Security group for RDS" \
  --vpc-id $VPC_ID \
  --query 'GroupId' \
  --output text)

# Allow PostgreSQL from ECS
aws ec2 authorize-security-group-ingress \
  --group-id $RDS_SG \
  --protocol tcp \
  --port 5432 \
  --source-group $ECS_SG

# Redis Security Group
REDIS_SG=$(aws ec2 create-security-group \
  --group-name myapp-redis-sg \
  --description "Security group for Redis" \
  --vpc-id $VPC_ID \
  --query 'GroupId' \
  --output text)

# Allow Redis from ECS
aws ec2 authorize-security-group-ingress \
  --group-id $REDIS_SG \
  --protocol tcp \
  --port 6379 \
  --source-group $ECS_SG
```

## Step 3: Create ECR Repositories

```bash
# Create ECR repositories
aws ecr create-repository --repository-name myapp/frontend
aws ecr create-repository --repository-name myapp/backend
aws ecr create-repository --repository-name myapp/worker

# Get ECR login
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

# Build and push images
docker build -t 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp/frontend:v1.0.0 ./frontend
docker build -t 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp/backend:v1.0.0 ./backend
docker build -t 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp/worker:v1.0.0 ./worker

docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp/frontend:v1.0.0
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp/backend:v1.0.0
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp/worker:v1.0.0
```

## Step 4: Create RDS PostgreSQL Database

```bash
# Create DB subnet group
aws rds create-db-subnet-group \
  --db-subnet-group-name myapp-db-subnet \
  --db-subnet-group-description "Subnet group for myapp database" \
  --subnet-ids $PRIVATE_SUBNET_1 $PRIVATE_SUBNET_2

# Create RDS instance
aws rds create-db-instance \
  --db-instance-identifier myapp-prod-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 16.1 \
  --master-username dbadmin \
  --master-user-password 'SecurePassword123!' \
  --allocated-storage 20 \
  --storage-type gp3 \
  --db-name myapp \
  --vpc-security-group-ids $RDS_SG \
  --db-subnet-group-name myapp-db-subnet \
  --backup-retention-period 7 \
  --no-publicly-accessible

# Wait for database to be available
aws rds wait db-instance-available --db-instance-identifier myapp-prod-db

# Get database endpoint
DB_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier myapp-prod-db \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

echo "Database endpoint: $DB_ENDPOINT"
```

## Step 5: Create ElastiCache Redis

```bash
# Create cache subnet group
aws elasticache create-cache-subnet-group \
  --cache-subnet-group-name myapp-redis-subnet \
  --cache-subnet-group-description "Subnet group for myapp redis" \
  --subnet-ids $PRIVATE_SUBNET_1 $PRIVATE_SUBNET_2

# Create Redis cluster
aws elasticache create-cache-cluster \
  --cache-cluster-id myapp-redis \
  --cache-node-type cache.t3.micro \
  --engine redis \
  --engine-version 7.0 \
  --num-cache-nodes 1 \
  --cache-subnet-group-name myapp-redis-subnet \
  --security-group-ids $REDIS_SG

# Wait for Redis to be available
aws elasticache wait cache-cluster-available --cache-cluster-id myapp-redis

# Get Redis endpoint
REDIS_ENDPOINT=$(aws elasticache describe-cache-clusters \
  --cache-cluster-id myapp-redis \
  --show-cache-node-info \
  --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' \
  --output text)

echo "Redis endpoint: $REDIS_ENDPOINT"
```

## Step 6: Store Secrets in Secrets Manager

```bash
# Store database credentials
aws secretsmanager create-secret \
  --name myapp/database \
  --secret-string "{\"username\":\"dbadmin\",\"password\":\"SecurePassword123!\",\"host\":\"$DB_ENDPOINT\",\"port\":5432,\"database\":\"myapp\"}"

# Store JWT secret
aws secretsmanager create-secret \
  --name myapp/jwt-secret \
  --secret-string "your-jwt-secret-key"

# Store Redis URL
aws secretsmanager create-secret \
  --name myapp/redis-url \
  --secret-string "redis://$REDIS_ENDPOINT:6379"
```

## Step 7: Create IAM Roles

```bash
# Create ECS task execution role
cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role \
  --role-name myapp-ecs-execution-role \
  --assume-role-policy-document file://trust-policy.json

# Attach policies
aws iam attach-role-policy \
  --role-name myapp-ecs-execution-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

# Create policy for Secrets Manager access
cat > secrets-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:secretsmanager:us-east-1:123456789012:secret:myapp/*"
      ]
    }
  ]
}
EOF

aws iam create-policy \
  --policy-name myapp-secrets-policy \
  --policy-document file://secrets-policy.json

aws iam attach-role-policy \
  --role-name myapp-ecs-execution-role \
  --policy-arn arn:aws:iam::123456789012:policy/myapp-secrets-policy

# Create ECS task role
aws iam create-role \
  --role-name myapp-ecs-task-role \
  --assume-role-policy-document file://trust-policy.json
```

## Step 8: Create Application Load Balancer

```bash
# Create ALB
ALB_ARN=$(aws elbv2 create-load-balancer \
  --name myapp-alb \
  --subnets $PUBLIC_SUBNET_1 $PUBLIC_SUBNET_2 \
  --security-groups $ALB_SG \
  --scheme internet-facing \
  --type application \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text)

# Create target groups
FRONTEND_TG=$(aws elbv2 create-target-group \
  --name myapp-frontend-tg \
  --protocol HTTP \
  --port 3000 \
  --vpc-id $VPC_ID \
  --target-type ip \
  --health-check-path / \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

BACKEND_TG=$(aws elbv2 create-target-group \
  --name myapp-backend-tg \
  --protocol HTTP \
  --port 8000 \
  --vpc-id $VPC_ID \
  --target-type ip \
  --health-check-path /health \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

# Create listener
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=$FRONTEND_TG

# Add rule for backend
aws elbv2 create-rule \
  --listener-arn $(aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN --query 'Listeners[0].ListenerArn' --output text) \
  --priority 1 \
  --conditions Field=path-pattern,Values='/api/*' \
  --actions Type=forward,TargetGroupArn=$BACKEND_TG

# Get ALB DNS name
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns $ALB_ARN \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

echo "ALB DNS: $ALB_DNS"
```

## Step 9: Create ECS Cluster

```bash
# Create ECS cluster
aws ecs create-cluster --cluster-name myapp-cluster

# Create CloudWatch log group
aws logs create-log-group --log-group-name /ecs/myapp
```

## Step 10: Create Task Definitions

```bash
# Backend task definition
cat > backend-task-def.json <<EOF
{
  "family": "myapp-backend",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::123456789012:role/myapp-ecs-execution-role",
  "taskRoleArn": "arn:aws:iam::123456789012:role/myapp-ecs-task-role",
  "containerDefinitions": [
    {
      "name": "backend",
      "image": "123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp/backend:v1.0.0",
      "portMappings": [
        {
          "containerPort": 8000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "ENVIRONMENT",
          "value": "production"
        }
      ],
      "secrets": [
        {
          "name": "DATABASE_URL",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:123456789012:secret:myapp/database"
        },
        {
          "name": "JWT_SECRET",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:123456789012:secret:myapp/jwt-secret"
        },
        {
          "name": "REDIS_URL",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:123456789012:secret:myapp/redis-url"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/myapp",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "backend"
        }
      }
    }
  ]
}
EOF

aws ecs register-task-definition --cli-input-json file://backend-task-def.json

# Frontend task definition (similar structure)
# Worker task definition (similar structure)
```

## Step 11: Create ECS Services

```bash
# Create backend service
aws ecs create-service \
  --cluster myapp-cluster \
  --service-name myapp-backend \
  --task-definition myapp-backend \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$PUBLIC_SUBNET_1,$PUBLIC_SUBNET_2],securityGroups=[$ECS_SG],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=$BACKEND_TG,containerName=backend,containerPort=8000"

# Create frontend service
aws ecs create-service \
  --cluster myapp-cluster \
  --service-name myapp-frontend \
  --task-definition myapp-frontend \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$PUBLIC_SUBNET_1,$PUBLIC_SUBNET_2],securityGroups=[$ECS_SG],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=$FRONTEND_TG,containerName=frontend,containerPort=3000"

# Create worker service (no load balancer)
aws ecs create-service \
  --cluster myapp-cluster \
  --service-name myapp-worker \
  --task-definition myapp-worker \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$PRIVATE_SUBNET_1,$PRIVATE_SUBNET_2],securityGroups=[$ECS_SG]}"
```

## Step 12: Configure Auto Scaling

```bash
# Register scalable target
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --resource-id service/myapp-cluster/myapp-backend \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity 2 \
  --max-capacity 10

# Create scaling policy
aws application-autoscaling put-scaling-policy \
  --service-namespace ecs \
  --resource-id service/myapp-cluster/myapp-backend \
  --scalable-dimension ecs:service:DesiredCount \
  --policy-name myapp-backend-cpu-scaling \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration file://scaling-policy.json

# scaling-policy.json
cat > scaling-policy.json <<EOF
{
  "TargetValue": 70.0,
  "PredefinedMetricSpecification": {
    "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
  },
  "ScaleInCooldown": 300,
  "ScaleOutCooldown": 60
}
EOF
```

## Monitoring and Logs

```bash
# View service status
aws ecs describe-services \
  --cluster myapp-cluster \
  --services myapp-backend

# View tasks
aws ecs list-tasks \
  --cluster myapp-cluster \
  --service-name myapp-backend

# View logs
aws logs tail /ecs/myapp --follow --filter-pattern backend
```

## Cleanup

```bash
# Delete ECS services
aws ecs delete-service --cluster myapp-cluster --service myapp-backend --force
aws ecs delete-service --cluster myapp-cluster --service myapp-frontend --force
aws ecs delete-service --cluster myapp-cluster --service myapp-worker --force

# Delete ECS cluster
aws ecs delete-cluster --cluster myapp-cluster

# Delete RDS instance
aws rds delete-db-instance \
  --db-instance-identifier myapp-prod-db \
  --skip-final-snapshot

# Delete ElastiCache cluster
aws elasticache delete-cache-cluster --cache-cluster-id myapp-redis

# Delete ALB
aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN

# Delete target groups
aws elbv2 delete-target-group --target-group-arn $FRONTEND_TG
aws elbv2 delete-target-group --target-group-arn $BACKEND_TG

# Delete VPC (after all resources are deleted)
aws ec2 delete-vpc --vpc-id $VPC_ID
```

## Cost Estimation

**Monthly costs (approximate):**
- ECS Fargate (5 tasks, 0.25 vCPU, 0.5 GB): $30
- RDS PostgreSQL (db.t3.micro): $15
- ElastiCache Redis (cache.t3.micro): $12
- Application Load Balancer: $16
- Data transfer: $10-50
- ECR storage: $1 per GB

**Total: ~$85-125/month** (varies with usage)

## Best Practices

1. **Use Fargate** for simplified container management
2. **Multi-AZ deployment** for high availability
3. **Private subnets** for databases and cache
4. **Secrets Manager** for sensitive data
5. **Auto scaling** based on metrics
6. **Health checks** for all services
7. **CloudWatch** for monitoring and alerting
8. **VPC endpoints** to reduce data transfer costs
9. **IAM roles** instead of access keys
10. **Regular backups** of RDS and automated snapshots
