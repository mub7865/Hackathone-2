---
name: cloud-deployment
description: >
  Complete patterns for deploying applications to cloud platforms (Azure, AWS, GCP):
  Infrastructure as Code, serverless deployments, cloud-native services, CI/CD pipelines,
  and production-ready cloud configurations.
---

# Cloud Deployment Skill

## When to use this Skill

Use this Skill whenever you are:

- Deploying applications to Azure, AWS, or GCP
- Creating Infrastructure as Code (Terraform, CloudFormation, ARM templates)
- Setting up serverless functions (Azure Functions, AWS Lambda, Cloud Functions)
- Configuring cloud-native services (databases, storage, messaging)
- Building CI/CD pipelines for cloud deployment
- Setting up monitoring and logging in cloud environments

This Skill works for **any** cloud platform and deployment scenario.

## Core Goals

- Create **production-ready** cloud deployments
- Follow **cloud best practices** for each platform
- Implement proper **security** and **access control**
- Use **Infrastructure as Code** for reproducibility
- Set up **monitoring and alerting** for reliability
- Provide **consistent patterns** across cloud providers

## Cloud Platforms Overview

### Platform Comparison

| Feature | Azure | AWS | GCP |
|---------|-------|-----|-----|
| **Compute** | App Service, Container Apps | Elastic Beanstalk, ECS | App Engine, Cloud Run |
| **Serverless** | Azure Functions | AWS Lambda | Cloud Functions |
| **Containers** | AKS (Kubernetes) | EKS (Kubernetes) | GKE (Kubernetes) |
| **Database** | Azure SQL, Cosmos DB | RDS, DynamoDB | Cloud SQL, Firestore |
| **Storage** | Blob Storage | S3 | Cloud Storage |
| **IaC** | ARM Templates, Bicep | CloudFormation | Deployment Manager |
| **CLI** | az | aws | gcloud |

## Azure Deployment

### Azure App Service (Web Apps)

**Best for:** Web applications, APIs, backends

```bash
# Create resource group
az group create --name myapp-rg --location eastus

# Create App Service plan
az appservice plan create \
  --name myapp-plan \
  --resource-group myapp-rg \
  --sku B1 \
  --is-linux

# Create web app
az webapp create \
  --name myapp \
  --resource-group myapp-rg \
  --plan myapp-plan \
  --runtime "NODE:20-lts"

# Deploy from Docker
az webapp config container set \
  --name myapp \
  --resource-group myapp-rg \
  --docker-custom-image-name myregistry.azurecr.io/myapp:latest

# Configure environment variables
az webapp config appsettings set \
  --name myapp \
  --resource-group myapp-rg \
  --settings DATABASE_URL="postgresql://..." API_KEY="..."

# Enable continuous deployment
az webapp deployment container config \
  --name myapp \
  --resource-group myapp-rg \
  --enable-cd true
```

### Azure Container Apps

**Best for:** Microservices, event-driven applications

```bash
# Create Container Apps environment
az containerapp env create \
  --name myapp-env \
  --resource-group myapp-rg \
  --location eastus

# Deploy container app
az containerapp create \
  --name myapp \
  --resource-group myapp-rg \
  --environment myapp-env \
  --image myregistry.azurecr.io/myapp:latest \
  --target-port 8000 \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 10 \
  --cpu 0.5 \
  --memory 1.0Gi \
  --env-vars DATABASE_URL="postgresql://..." API_KEY="..."

# Update container app
az containerapp update \
  --name myapp \
  --resource-group myapp-rg \
  --image myregistry.azurecr.io/myapp:v2
```

### Azure Functions (Serverless)

**Best for:** Event-driven functions, background jobs

```bash
# Create storage account (required for Functions)
az storage account create \
  --name myappstorage \
  --resource-group myapp-rg \
  --location eastus \
  --sku Standard_LRS

# Create function app
az functionapp create \
  --name myapp-functions \
  --resource-group myapp-rg \
  --storage-account myappstorage \
  --consumption-plan-location eastus \
  --runtime node \
  --runtime-version 20 \
  --functions-version 4

# Deploy function code
func azure functionapp publish myapp-functions
```

## AWS Deployment

### AWS Elastic Beanstalk

**Best for:** Web applications, APIs

```bash
# Initialize Elastic Beanstalk
eb init -p node.js-20 myapp --region us-east-1

# Create environment
eb create myapp-prod \
  --instance-type t3.small \
  --envvars DATABASE_URL="postgresql://...",API_KEY="..."

# Deploy application
eb deploy

# Check status
eb status

# View logs
eb logs

# Terminate environment
eb terminate myapp-prod
```

### AWS ECS (Elastic Container Service)

**Best for:** Containerized applications

```bash
# Create ECS cluster
aws ecs create-cluster --cluster-name myapp-cluster

# Register task definition
aws ecs register-task-definition --cli-input-json file://task-definition.json

# Create service
aws ecs create-service \
  --cluster myapp-cluster \
  --service-name myapp-service \
  --task-definition myapp:1 \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}"

# Update service
aws ecs update-service \
  --cluster myapp-cluster \
  --service myapp-service \
  --task-definition myapp:2 \
  --force-new-deployment
```

### AWS Lambda (Serverless)

**Best for:** Event-driven functions, APIs

```bash
# Create Lambda function
aws lambda create-function \
  --function-name myapp-function \
  --runtime nodejs20.x \
  --role arn:aws:iam::123456789012:role/lambda-role \
  --handler index.handler \
  --zip-file fileb://function.zip \
  --environment Variables={DATABASE_URL="postgresql://...",API_KEY="..."}

# Update function code
aws lambda update-function-code \
  --function-name myapp-function \
  --zip-file fileb://function.zip

# Invoke function
aws lambda invoke \
  --function-name myapp-function \
  --payload '{"key":"value"}' \
  response.json
```

## GCP Deployment

### Google App Engine

**Best for:** Web applications, APIs

```bash
# Initialize App Engine
gcloud app create --region=us-central

# Deploy application
gcloud app deploy app.yaml

# View application
gcloud app browse

# View logs
gcloud app logs tail -s default

# Set environment variables
gcloud app deploy --set-env-vars DATABASE_URL="postgresql://...",API_KEY="..."
```

### Google Cloud Run

**Best for:** Containerized applications, APIs

```bash
# Deploy container
gcloud run deploy myapp \
  --image gcr.io/myproject/myapp:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8000 \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 1 \
  --max-instances 10 \
  --set-env-vars DATABASE_URL="postgresql://...",API_KEY="..."

# Update service
gcloud run services update myapp \
  --image gcr.io/myproject/myapp:v2 \
  --region us-central1

# View logs
gcloud run logs read --service myapp --region us-central1
```

### Google Cloud Functions

**Best for:** Event-driven functions

```bash
# Deploy function
gcloud functions deploy myapp-function \
  --runtime nodejs20 \
  --trigger-http \
  --allow-unauthenticated \
  --entry-point handler \
  --set-env-vars DATABASE_URL="postgresql://...",API_KEY="..."

# Update function
gcloud functions deploy myapp-function \
  --source . \
  --runtime nodejs20

# View logs
gcloud functions logs read myapp-function
```

## Infrastructure as Code

### Terraform (Multi-Cloud)

**Best for:** Managing infrastructure across multiple clouds

```hcl
# Azure example
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "myapp-rg"
  location = "East US"
}

resource "azurerm_app_service_plan" "main" {
  name                = "myapp-plan"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_app_service" "main" {
  name                = "myapp"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  app_service_plan_id = azurerm_app_service_plan.main.id

  site_config {
    linux_fx_version = "NODE|20-lts"
  }

  app_settings = {
    "DATABASE_URL" = var.database_url
    "API_KEY"      = var.api_key
  }
}
```

### AWS CloudFormation

**Best for:** AWS infrastructure

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'ECS Fargate deployment'

Resources:
  ECSCluster:
    Type: AWS::ECS::Cluster
    Properties:
      ClusterName: myapp-cluster

  TaskDefinition:
    Type: AWS::ECS::TaskDefinition
    Properties:
      Family: myapp
      NetworkMode: awsvpc
      RequiresCompatibilities:
        - FARGATE
      Cpu: 256
      Memory: 512
      ContainerDefinitions:
        - Name: myapp
          Image: !Sub ${AWS::AccountId}.dkr.ecr.${AWS::Region}.amazonaws.com/myapp:latest
          PortMappings:
            - ContainerPort: 8000
          Environment:
            - Name: DATABASE_URL
              Value: !Ref DatabaseURL
```

### Azure ARM Templates

**Best for:** Azure infrastructure

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "resources": [
    {
      "type": "Microsoft.Web/serverfarms",
      "apiVersion": "2021-02-01",
      "name": "myapp-plan",
      "location": "[resourceGroup().location]",
      "sku": {
        "name": "B1",
        "tier": "Basic"
      },
      "kind": "linux",
      "properties": {
        "reserved": true
      }
    }
  ]
}
```

## CI/CD Pipelines

### GitHub Actions (Multi-Cloud)

```yaml
name: Deploy to Cloud

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Build Docker image
        run: docker build -t myapp:${{ github.sha }} .

      - name: Deploy to Azure
        uses: azure/webapps-deploy@v2
        with:
          app-name: myapp
          images: myregistry.azurecr.io/myapp:${{ github.sha }}
```

## Best Practices

### Security

1. **Use managed identities**: Avoid storing credentials
2. **Enable HTTPS**: Always use TLS/SSL
3. **Implement RBAC**: Least privilege access
4. **Use secrets management**: Azure Key Vault, AWS Secrets Manager, GCP Secret Manager
5. **Enable logging**: Track all access and changes

### Cost Optimization

1. **Right-size resources**: Don't over-provision
2. **Use autoscaling**: Scale based on demand
3. **Use spot/preemptible instances**: For non-critical workloads
4. **Set up budgets and alerts**: Monitor spending
5. **Use reserved instances**: For predictable workloads

### Reliability

1. **Deploy to multiple regions**: High availability
2. **Use health checks**: Automatic recovery
3. **Implement retry logic**: Handle transient failures
4. **Set up monitoring**: Proactive issue detection
5. **Test disaster recovery**: Regular backups and restore tests

## References

- [Azure Documentation](https://docs.microsoft.com/azure/)
- [AWS Documentation](https://docs.aws.amazon.com/)
- [GCP Documentation](https://cloud.google.com/docs)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Cloud Architecture Patterns](https://docs.microsoft.com/azure/architecture/patterns/)
