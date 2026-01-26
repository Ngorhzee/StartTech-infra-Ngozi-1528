#!/bin/bash
pwd
pushd ../terraform
terraform init -upgrade=false
terraform plan
terraform apply --auto-approve
# S3BUCKET_NAME=$(terraform output -raw s3bucket_name)

popd 

pwd
# docker build -f ../Dockerfile.front -t frontend-build:latest .
# docker create --name temp-frontend-build frontend-build:latest
# docker cp temp-frontend-build:/app/dist ./build-output
# docker rm temp-frontend-build

# pwd
# aws s3 sync ./build-output/ s3://$S3BUCKET_NAME/

# rm -rf ./build-output

# # Build and push backend Docker image
# ECR_REPO=$(terraform -chdir=../terraform output -raw ecr_repository_url)
# aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin $ECR_REPO

# docker build -f Dockerfile.back -t starttech-backend:latest .
# docker tag starttech-backend:latest $ECR_REPO:latest
# docker push $ECR_REPO:latest