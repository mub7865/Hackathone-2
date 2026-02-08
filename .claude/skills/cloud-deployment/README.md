# Cloud Deployment Skill

## Overview

This skill provides complete patterns and best practices for deploying applications to cloud platforms (Azure, AWS, GCP). It covers Infrastructure as Code, serverless deployments, cloud-native services, CI/CD pipelines, and production-ready configurations.

## Supported Platforms

- **Azure**: App Service, Container Apps, AKS, Azure Functions
- **AWS**: Elastic Beanstalk, ECS, EKS, Lambda
- **GCP**: App Engine, Cloud Run, GKE, Cloud Functions

## Key Features

- Infrastructure as Code (Terraform, CloudFormation, ARM templates)
- Serverless deployment patterns
- Container orchestration (Kubernetes)
- CI/CD pipeline configurations
- Security and access control
- Monitoring and logging setup
- Cost optimization strategies

## Quick Reference

### Azure Deployment

```bash
# Deploy to Azure App Service
az webapp create \
  --name myapp \
  --resource-group myapp-rg \
  --plan myapp-plan \
  --runtime "NODE:20-lts"

# Deploy container to Azure Container Apps
az containerapp create \
  --name myapp \
  --resource-group myapp-rg \
  --environment myapp-env \
  --image myregistry.azurecr.io/myapp:latest \
  --target-port 8000 \
  --ingress external
```

### AWS Deployment

```bash
# Deploy to AWS Elastic Beanstalk
eb init -p node.js-20 myapp
eb create myapp-prod
eb deploy

# Deploy to AWS ECS
aws ecs create-service \
  --cluster myapp-cluster \
  --service-name myapp-service \
  --task-definition myapp:1 \
  --desired-count 2
```

### GCP Deployment

```bash
# Deploy to Google Cloud Run
gcloud run deploy myapp \
  --image gcr.io/myproject/myapp:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated

# Deploy to Google App Engine
gcloud app deploy app.yaml
```

## Files

- `SKILL.md` - Complete skill documentation
- `Templates/` - IaC templates (Terraform, CloudFormation, ARM)
- `Examples/` - Real-world deployment examples
- `Testing/` - Verification scripts
- `Troubleshooting/` - Common issues and solutions

## Usage

Reference this skill when:
- Deploying applications to cloud platforms
- Creating Infrastructure as Code
- Setting up CI/CD pipelines
- Configuring cloud-native services
- Implementing security and monitoring

## Best Practices

1. **Use Infrastructure as Code**: Terraform, CloudFormation, ARM templates
2. **Implement CI/CD**: Automate deployments with GitHub Actions, Azure DevOps, AWS CodePipeline
3. **Enable monitoring**: Application Insights, CloudWatch, Cloud Monitoring
4. **Secure secrets**: Key Vault, Secrets Manager, Secret Manager
5. **Use managed services**: Reduce operational overhead
6. **Implement autoscaling**: Handle variable load efficiently
7. **Deploy to multiple regions**: High availability
8. **Set up cost alerts**: Monitor and optimize spending

## Sources

- [Azure Documentation](https://docs.microsoft.com/azure/)
- [AWS Documentation](https://docs.aws.amazon.com/)
- [GCP Documentation](https://cloud.google.com/docs)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Cloud Architecture Center](https://docs.microsoft.com/azure/architecture/)
