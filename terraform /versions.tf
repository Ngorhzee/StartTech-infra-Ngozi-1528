terraform {
  required_version = ">= 1.0"
  required_providers {
    aws ={
        source = "hashicorp/aws"
        version = ">=6.0.0"
    }
  }
   backend "s3" {
    bucket         = "starttech-terraform-state-sts"   # Replace with unique bucket name
    key            = "starttech-infra/terraform.tfstate"
    region         = "eu-west-1"
    use_lockfile = true
    encrypt        = true
  }
}

provider "aws" {
region = "eu-west-1"
  
}