# Monitoring Configuration Guide

This directory contains CloudWatch monitoring configuration files for the StartTech infrastructure. These files serve as templates and reference documentation for setting up comprehensive monitoring, alerting, and log analysis.

## Files Overview

### 1. `cloudwatch-dashboard.json`
A comprehensive CloudWatch Dashboard configuration that visualizes:
- Backend EC2 CPU utilization and network traffic
- ALB request counts, response times, and status codes
- Target health status
- Auto Scaling Group capacity
- CloudFront requests, data transfer, and cache performance
- Application error logs

### 2. `alarm-definitions.json`
CloudWatch Alarm definitions for:
- High CPU utilization (70% and 90% thresholds)
- Unhealthy ALB targets
- High ALB response times
- High 4xx and 5xx error rates
- ASG instance terminations
- CloudFront error rates and cache performance

### 3. `log-insights-queries.txt`
Pre-built CloudWatch Logs Insights queries for:
- Error analysis and tracking
- Request pattern analysis
- Performance monitoring
- Application health checks
- Security monitoring
- API endpoint analysis

## Getting Actual Values

### Method 1: Using Terraform Outputs (Recommended)

After deploying your infrastructure, run these commands to get the actual values:
sh
cd terraform

# Get all outputs
terraform output

# Get specific values
terraform output -raw project_name          # e.g., "starttech"
terraform output -raw asg_name              # e.g., "starttech-backend-asg"
terraform output -raw alb_arn_suffix         # e.g., "app/starttech-backend-alb/..."
terraform output -raw target_group_arn_suffix # e.g., "targetgroup/..."
terraform output -raw cloudfront_distribution_id # e.g., "E1234567890ABC"
terraform output -raw aws_region            # e.g., "eu-west-1"
terraform output -raw sns_topic_arn         # e.g., "arn:aws:sns:eu-west-1:123456789012:starttech-alarms"
