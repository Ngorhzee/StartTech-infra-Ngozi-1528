#!/bin/bash
cd monitoring

# Get values
ASG_NAME=$(cd .. && terraform output -raw asg_name)
ALB_ARN=$(cd .. && terraform output -raw alb_arn_suffix)
TG_ARN=$(cd .. && terraform output -raw target_group_arn_suffix)
CF_ID=$(cd .. && terraform output -raw cloudfront_distribution_id)
AWS_REGION=$(cd .. && terraform output -raw aws_region)
PROJECT_NAME=$(cd .. && terraform output -raw project_name)

# Create a backup
cp cloudwatch-dashboard.json cloudwatch-dashboard.json.bak

# Replace placeholders (using sed)
sed -i '' \
  -e "s|\${asg_name}|$ASG_NAME|g" \
  -e "s|\${alb_arn_suffix}|$ALB_ARN|g" \
  -e "s|\${target_group_arn_suffix}|$TG_ARN|g" \
  -e "s|\${cloudfront_distribution_id}|$CF_ID|g" \
  -e "s|\${aws_region}|$AWS_REGION|g" \
  -e "s|\${project_name}|$PROJECT_NAME|g" \
  cloudwatch-dashboard.json

if python3 -m json.tool cloudwatch-dashboard.json > /dev/null 2>&1; then
  echo "✓ JSON is valid!"
  echo "You can now use: aws cloudwatch put-dashboard --dashboard-name starttech-infrastructure-dashboard --dashboard-body file://cloudwatch-dashboard.json --region $AWS_REGION"
else
  echo "✗ JSON validation failed! Restoring backup..."
  mv cloudwatch-dashboard.json.bak cloudwatch-dashboard.json
  exit 1
fi