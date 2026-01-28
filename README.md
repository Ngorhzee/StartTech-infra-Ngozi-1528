# StartTech Infrastructure

Comprehensive Infrastructure as Code (IaC) setup for the StartTech application using Terraform on AWS.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [CI/CD](#cicd)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Cost Estimation](#cost-estimation)

## 🎯 Overview

This repository contains Terraform modules to deploy a production-ready infrastructure on AWS, including:

- **Networking**: VPC with public and private subnets across multiple availability zones
- **Compute**: Auto Scaling Group with EC2 instances running containerized backend
- **Load Balancing**: Application Load Balancer for high availability
- **Storage**: S3 bucket for frontend static hosting
- **CDN**: CloudFront distribution for global content delivery
- **Container Registry**: ECR for Docker image storage
- **Monitoring**: CloudWatch dashboards, alarms, and log groups
- **Security**: IAM roles, security groups, and access policies

## 📦 Prerequisites

Before you begin, ensure you have:

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured
   aws --version
   aws configure
3. **Terraform** installed 
   terraform --version
4. **Docker** installed 
   docker --version
5. **Git** for cloning the repository
6. **Required Secrets** 
 - MongoDB connection URI
 - Database name
 - JWT secret key

## 🏗️ Architecture
See ARCHITECTURE.md for detailed architecture documentation.

**High-Level Overview:**
Internet
    ↓
CloudFront (CDN)
    ↓
S3 Bucket (Frontend)
    ↓
Application Load Balancer
    ↓
Auto Scaling Group (EC2 Instances)
    ↓
Docker Containers (Backend API)
    ↓
MongoDB (External)

## 🚀 Quick Start
1. **Clone the Repository**
```bash
git clone <https://github.com/Ngorhzee/StartTech-infra-Ngozi-1528>
cd starttech-infra
```
2. **Configure Variables**
Copy the example variables file and fill in your values:
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```
3. **Initialize Terraform**
```bash
terraform init
```
4. **Review the Plan**
```bash
terraform plan
```
5. **Deploy Infrastructure**
```bash
terraform apply
```
Type yes when prompted to confirm.

6. **Get Outputs**
```bash
terraform outputs
```
Save important outputs like:
- `alb_dns_name` - Application Load Balancer URL
- `s3bucket_name` - S3 bucket name
- `ecr_repository_url` - ECR repository URL for pushing images

**Or you could skip Step 3 to Step 5 and just run the script**
```bash
cd ./scripts
./deploy-infrastructue.sh
```

## ⚙️ Configuration
**Required Variables**

| Variables | Description | Example |
|----------|----------|----------|
| mongo_uri  | MongoDB connection string  | mongodb://user:pass@host:27017  |
| db_name | Database name | starttech_db |
| jwt_secret| JWT signing secret | your-secret-key-here|

**Module Configuration**
The infrastructure is organized into modules:
* **networking**: VPC, subnets, internet gateway
* **compute**: EC2, ASG, ALB, ECR, IAM roles
* **storage**: S3 bucket, CloudFront distribution
* **monitoring**: CloudWatch logs, alarms, dashboards

## 🚢 Deployment
**Automated Deployment (CI/CD)**
The repository includes GitHub Actions workflow for automated deployment:
1. **Configure GitHub Secrets:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `MONGO_URI`
- `DB_NAME`
- `JWT_SECRET`

2. **Push to Main Branch**
``` bash
git push origin main
```
The workflow will:
- Validate Terraform configuration
- Plan infrastructure changes
- Apply changes automatically
- Deploy on successful validation
See `.github/workflows/infrastructure-deploy.yml` for details.

## 📊 Monitoring
**CloudWatch Dashboard**
Access the dashboard:
1. Go to AWS Console → CloudWatch → Dashboards
2. Select starttech-dashboard
or Create manually using 
```
cd terraform
./tmp.sh
aws cloudwatch put-dashboard \
  --dashboard-name "starttech-infrastructure-dashboard" \
  --dashboard-body file://./monitoring/cloudwatch-dashboard.json \
  --region aws_region
```

**CloudWatch Alarms**
Pre-configured alarms:
- High CPU utilization (70% and 90%)
- Unhealthy ALB targets
- High response times
- High error rates (4xx, 5xx)

**Log Analysis**
Use CloudWatch Logs Insights queries from `terraform/monitoring/log-insights-queries.txt`:
1. Go to CloudWatch → Logs → Insights
2. Select log group: /starttech/backend
3. Copy and run queries
See `monitoring/README.md` for details.

## 🔧 Troubleshooting
**Common Issues**
1. **Terraform Init Fails**
```bash
# Solution: Clear cache and reinitialize
rm -rf .terraform
terraform init
```
2. **ECR Login Fails**
```bash
# Solution: Verify AWS credentials
aws sts get-caller-identity
aws ecr get-login-password --region eu-west-1
```
3. **ALB Health Checks Failing**
- Verify security groups allow traffic on port 8080
- Check EC2 instances are running
- Verify Docker container is healthy: `curl http://localhost:8080/health`

4. **CloudFront Not Serving Content**
- Verify S3 bucket policy allows CloudFront access
- Check CloudFront distribution status
- Clear CloudFront cache if needed

See [RUNBOOK.md](RUNBOOK.md) for detailed troubleshooting.

## 📚 Additional Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) – Detailed system architecture
- [RUNBOOK.md](RUNBOOK.md) – Operations and troubleshooting guide
- [Monitoring Setup](terraform/monitoring/README.md) – Monitoring setup



