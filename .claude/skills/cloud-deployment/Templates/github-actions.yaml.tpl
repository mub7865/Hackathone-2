# GitHub Actions CI/CD Templates for Cloud Deployment

---
# Deploy to Azure App Service
name: Deploy to Azure

on:
  push:
    branches: [main]
  workflow_dispatch:

env:
  AZURE_WEBAPP_NAME: myapp
  NODE_VERSION: '20.x'

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Set up Node.js
      uses: actions/setup-node@v3
      with:
        node-version: ${{ env.NODE_VERSION }}
        cache: 'npm'

    - name: Install dependencies
      run: npm ci

    - name: Build application
      run: npm run build

    - name: Run tests
      run: npm test

    - name: Deploy to Azure Web App
      uses: azure/webapps-deploy@v2
      with:
        app-name: ${{ env.AZURE_WEBAPP_NAME }}
        publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
        package: .

---
# Deploy to Azure Container Apps
name: Deploy to Azure Container Apps

on:
  push:
    branches: [main]

env:
  REGISTRY: myregistry.azurecr.io
  IMAGE_NAME: myapp
  CONTAINER_APP_NAME: myapp
  RESOURCE_GROUP: myapp-rg

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Log in to Azure
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}

    - name: Log in to Azure Container Registry
      uses: azure/docker-login@v1
      with:
        login-server: ${{ env.REGISTRY }}
        username: ${{ secrets.ACR_USERNAME }}
        password: ${{ secrets.ACR_PASSWORD }}

    - name: Build and push Docker image
      run: |
        docker build -t ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }} .
        docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}

    - name: Deploy to Azure Container Apps
      uses: azure/container-apps-deploy-action@v1
      with:
        containerAppName: ${{ env.CONTAINER_APP_NAME }}
        resourceGroup: ${{ env.RESOURCE_GROUP }}
        imageToDeploy: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}

---
# Deploy to AWS Elastic Beanstalk
name: Deploy to AWS

on:
  push:
    branches: [main]

env:
  AWS_REGION: us-east-1
  EB_APPLICATION_NAME: myapp
  EB_ENVIRONMENT_NAME: myapp-prod

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Set up Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '20.x'

    - name: Install dependencies
      run: npm ci

    - name: Build application
      run: npm run build

    - name: Generate deployment package
      run: zip -r deploy.zip . -x '*.git*'

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}

    - name: Deploy to Elastic Beanstalk
      uses: einaregilsson/beanstalk-deploy@v21
      with:
        aws_access_key: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws_secret_key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        application_name: ${{ env.EB_APPLICATION_NAME }}
        environment_name: ${{ env.EB_ENVIRONMENT_NAME }}
        version_label: ${{ github.sha }}
        region: ${{ env.AWS_REGION }}
        deployment_package: deploy.zip

---
# Deploy to AWS ECS
name: Deploy to AWS ECS

on:
  push:
    branches: [main]

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: myapp
  ECS_SERVICE: myapp-service
  ECS_CLUSTER: myapp-cluster
  ECS_TASK_DEFINITION: task-definition.json
  CONTAINER_NAME: myapp

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}

    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v1

    - name: Build, tag, and push image to Amazon ECR
      id: build-image
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        IMAGE_TAG: ${{ github.sha }}
      run: |
        docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
        echo "image=$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG" >> $GITHUB_OUTPUT

    - name: Fill in the new image ID in the Amazon ECS task definition
      id: task-def
      uses: aws-actions/amazon-ecs-render-task-definition@v1
      with:
        task-definition: ${{ env.ECS_TASK_DEFINITION }}
        container-name: ${{ env.CONTAINER_NAME }}
        image: ${{ steps.build-image.outputs.image }}

    - name: Deploy Amazon ECS task definition
      uses: aws-actions/amazon-ecs-deploy-task-definition@v1
      with:
        task-definition: ${{ steps.task-def.outputs.task-definition }}
        service: ${{ env.ECS_SERVICE }}
        cluster: ${{ env.ECS_CLUSTER }}
        wait-for-service-stability: true

---
# Deploy to Google Cloud Run
name: Deploy to GCP

on:
  push:
    branches: [main]

env:
  PROJECT_ID: my-project
  SERVICE_NAME: myapp
  REGION: us-central1

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Authenticate to Google Cloud
      uses: google-github-actions/auth@v1
      with:
        credentials_json: ${{ secrets.GCP_CREDENTIALS }}

    - name: Set up Cloud SDK
      uses: google-github-actions/setup-gcloud@v1

    - name: Configure Docker for GCR
      run: gcloud auth configure-docker

    - name: Build and push Docker image
      run: |
        docker build -t gcr.io/${{ env.PROJECT_ID }}/${{ env.SERVICE_NAME }}:${{ github.sha }} .
        docker push gcr.io/${{ env.PROJECT_ID }}/${{ env.SERVICE_NAME }}:${{ github.sha }}

    - name: Deploy to Cloud Run
      run: |
        gcloud run deploy ${{ env.SERVICE_NAME }} \
          --image gcr.io/${{ env.PROJECT_ID }}/${{ env.SERVICE_NAME }}:${{ github.sha }} \
          --platform managed \
          --region ${{ env.REGION }} \
          --allow-unauthenticated

---
# Multi-Environment Deployment (Dev, Staging, Prod)
name: Multi-Environment Deploy

on:
  push:
    branches:
      - dev
      - staging
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Determine environment
      id: env
      run: |
        if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
          echo "environment=prod" >> $GITHUB_OUTPUT
          echo "app_name=myapp-prod" >> $GITHUB_OUTPUT
        elif [[ "${{ github.ref }}" == "refs/heads/staging" ]]; then
          echo "environment=staging" >> $GITHUB_OUTPUT
          echo "app_name=myapp-staging" >> $GITHUB_OUTPUT
        else
          echo "environment=dev" >> $GITHUB_OUTPUT
          echo "app_name=myapp-dev" >> $GITHUB_OUTPUT
        fi

    - name: Set up Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '20.x'

    - name: Install dependencies
      run: npm ci

    - name: Build application
      run: npm run build
      env:
        NODE_ENV: ${{ steps.env.outputs.environment }}

    - name: Run tests
      run: npm test

    - name: Deploy to Azure
      uses: azure/webapps-deploy@v2
      with:
        app-name: ${{ steps.env.outputs.app_name }}
        publish-profile: ${{ secrets[format('AZURE_WEBAPP_PUBLISH_PROFILE_{0}', steps.env.outputs.environment)] }}
        package: .

---
# Terraform Deployment
name: Terraform Deploy

on:
  push:
    branches: [main]
    paths:
      - 'terraform/**'
  pull_request:
    branches: [main]
    paths:
      - 'terraform/**'

jobs:
  terraform:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: 1.6.0

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1

    - name: Terraform Init
      run: terraform init
      working-directory: ./terraform

    - name: Terraform Format
      run: terraform fmt -check
      working-directory: ./terraform

    - name: Terraform Validate
      run: terraform validate
      working-directory: ./terraform

    - name: Terraform Plan
      run: terraform plan -out=tfplan
      working-directory: ./terraform
      env:
        TF_VAR_database_password: ${{ secrets.DATABASE_PASSWORD }}

    - name: Terraform Apply
      if: github.ref == 'refs/heads/main' && github.event_name == 'push'
      run: terraform apply -auto-approve tfplan
      working-directory: ./terraform

---
# Docker Build and Push (Multi-Registry)
name: Build and Push Docker Image

on:
  push:
    branches: [main]
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2

    - name: Log in to Docker Hub
      uses: docker/login-action@v2
      with:
        username: ${{ secrets.DOCKERHUB_USERNAME }}
        password: ${{ secrets.DOCKERHUB_TOKEN }}

    - name: Log in to Azure Container Registry
      uses: docker/login-action@v2
      with:
        registry: myregistry.azurecr.io
        username: ${{ secrets.ACR_USERNAME }}
        password: ${{ secrets.ACR_PASSWORD }}

    - name: Log in to Amazon ECR
      uses: aws-actions/amazon-ecr-login@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1

    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v4
      with:
        images: |
          myusername/myapp
          myregistry.azurecr.io/myapp
          123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=semver,pattern={{version}}
          type=semver,pattern={{major}}.{{minor}}
          type=sha

    - name: Build and push
      uses: docker/build-push-action@v4
      with:
        context: .
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

---
# Best Practices for CI/CD

# 1. Use secrets for sensitive data
# - Never hardcode credentials
# - Use GitHub Secrets for API keys, passwords, etc.

# 2. Use environment-specific configurations
# - Separate dev, staging, and prod environments
# - Use different secrets for each environment

# 3. Run tests before deployment
# - Unit tests
# - Integration tests
# - Security scans

# 4. Use caching
# - Cache dependencies (npm, pip, etc.)
# - Cache Docker layers
# - Speeds up builds significantly

# 5. Implement rollback strategy
# - Keep previous versions
# - Use blue-green or canary deployments
# - Monitor deployments

# 6. Use matrix builds for multiple targets
# - Test on multiple Node.js versions
# - Deploy to multiple regions
# - Build for multiple platforms

# 7. Add status checks
# - Require passing tests before merge
# - Require code review
# - Require security scans

# 8. Use workflow artifacts
# - Save build artifacts
# - Share between jobs
# - Download for debugging

# 9. Implement proper error handling
# - Fail fast on errors
# - Send notifications on failure
# - Retry transient failures

# 10. Monitor deployments
# - Track deployment metrics
# - Set up alerts
# - Log all deployments
