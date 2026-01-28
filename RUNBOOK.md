# StartTech Infrastructure Runbook

Operations and troubleshooting guide for the StartTech infrastructure.

## 📋 Table of Contents

- [Quick Reference](#quick-reference)
- [Common Operations](#common-operations)
- [Troubleshooting](#troubleshooting)
- [Emergency Procedures](#emergency-procedures)
- [Maintenance Tasks](#maintenance-tasks)
- [Monitoring & Alerts](#monitoring--alerts)

## 🚀 Quick Reference

### Important Commands

# Get infrastructure outputs
cd terraform && terraform output

# View Terraform state
terraform show

# Check infrastructure status
aws ec2 describe-instances --filters "Name=tag:Name,Values=starttech*"
aws elbv2 describe-load-balancers --names starttech-backend-alb

# View logs
aws logs tail /starttech/backend --follow

# Check ALB health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
# 🔑 Key Resources

| Resource | How to Access |
|--------|---------------|
| **ALB URL** | `terraform output alb_dns_name` |
| **S3 Bucket** | `terraform output s3bucket_name` |
| **ECR Repository** | `terraform output ecr_repository_url` |
| **CloudWatch Dashboard** | AWS Console → CloudWatch → Dashboards |
| **Log Groups** | AWS Console → CloudWatch → Logs → Log groups |

---

# 🔧 Common Operations

**Deploy New Backend Version**

```bash
# 1. Get ECR repository URL
ECR_REPO=$(cd terraform && terraform output -raw ecr_repository_url)

# 2. Build new image
docker build -f Dockerfile.back -t starttech-backend:latest .

# 3. Tag and push
docker tag starttech-backend:latest $ECR_REPO:latest
aws ecr get-login-password --region eu-west-1 | \
  docker login --username AWS --password-stdin $ECR_REPO
docker push $ECR_REPO:latest

# 4. Force instance refresh (optional)
ASG_NAME=$(cd terraform && terraform output -raw asg_name)
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name $ASG_NAME \
  --preferences MinHealthyPercentage=50
```
**Scale Up/Down Instances**
```bash
# Get ASG name
ASG_NAME=$(cd terraform && terraform output -raw asg_name)

# Scale up to 4 instances
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name $ASG_NAME \
  --desired-capacity 4

# Scale down to 2 instances
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name $ASG_NAME \
  --desired-capacity 2
```
**View Application Logs**
```bash
# Tail backend logs
aws logs tail /starttech/backend --follow

# Query logs with CloudWatch Logs Insights
# Go to: AWS Console → CloudWatch → Logs → Insights
# Select log group: /starttech/backend
# Use queries from terraform/monitoring/log-insights-queries.txt
```
**Check System Health**
```bash
# 1. Check ALB target health
ALB_ARN=$(cd terraform && terraform output -raw alb_arn_suffix)
TG_ARN=$(cd terraform && terraform output -raw target_group_arn_suffix)

aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:eu-west-1:ACCOUNT:targetgroup/$TG_ARN

# 2. Check EC2 instance status
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=starttech*" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]' \
  --output table

# 3. Check CloudWatch metrics
# Go to: AWS Console → CloudWatch → Metrics
```
# 🐛 Troubleshooting

## Issue: ALB Health Checks Failing

### Symptoms
- Targets showing as unhealthy  
- 502/503 errors  
- No traffic reaching backend  

### Diagnosis

```bash
# 1. Check target health
TG_ARN=$(cd terraform && terraform output -raw target_group_arn_suffix)
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:eu-west-1:ACCOUNT:targetgroup/$TG_ARN

# 2. Check security groups
# ALB SG should allow outbound to backend SG
# Backend SG should allow inbound from ALB SG on port 8080

# 3. SSH into instance and check container
aws ssm start-session --target <instance-id>
docker ps
docker logs <container-id>
curl http://localhost:8080/health
```
**Solutions:**
1. **Cache Issue**: Invalidate CloudFront cache
2. **S3 Policy**: Verify OAI has access to S3 bucket
3. **Distribution Status**: Ensure distribution is deployed
4. **Origin Configuration**: Verify S3 bucket is correct origin

**Issue: Cannot SSH into Instances**
**Symtoms**
- SSM Session Manager fails
- Need to debug instance
**Solutions:**
```bash
# Use SSM Session Manager (recommended)
aws ssm start-session --target <instance-id>

# If SSM not working, check:
# 1. IAM role has SSM permissions
# 2. SSM agent is installed (should be in user data)
# 3. Instance is in running state
```
## 🚨 Emergency Procedures
**Complete Service Outage**
**Immediate Actions:**
1. Check CloudWatch dashboard for overall health
2. Verify ALB is responding: `curl http://<alb-dns-name>/health`
3. Check ASG instance count
4. Review recent deployments
**Recovery Steps:**
```bash
# 1. Check all components
terraform output

# 2. Verify instances are running
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $(terraform output -raw asg_name)

# 3. Force instance refresh if needed
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name $(terraform output -raw asg_name)

# 4. Rollback to previous version if needed
# (Revert to previous ECR image tag)
```
**Database Connection Lost**
**Symptoms:**
- All requests failing
- Database connection errors in logs
**Actions:**
1. Verify MongoDB is accessible
2. Check security groups allow outbound traffic
3. Verify MongoDB URI is correct
4. Test connection from instance: 
```bash
   aws ssm start-session --target <instance-id>
   # Test MongoDB connection from container
```
**Security Incident**
**Immediate Actions:**
1. **Isolate Affected Resources**: Detach from ALB
2. **Review Logs**: Check for unauthorized access
3. **Rotate Credentials**: Change JWT secret, database passwords
4. **Notify Team**: Alert security team
**Steps:**
```bash
# 1. Set ASG desired capacity to 0 (stop all instances)
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name $(terraform output -raw asg_name) \
  --desired-capacity 0

# 2. Review security groups
aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=starttech*"

# 3. Review CloudTrail logs (if enabled)
# Go to: AWS Console → CloudTrail → Event history
```
# 🔄 Maintenance Tasks

## Weekly Tasks
- [ ] Review CloudWatch dashboards
- [ ] Check alarm history
- [ ] Review error logs
- [ ] Verify backup processes (if applicable)

## Monthly Tasks
- [ ] Review and optimize costs
- [ ] Update Terraform and provider versions
- [ ] Review security groups and IAM policies
- [ ] Check for outdated container images
- [ ] Review and update documentation

## Quarterly Tasks
- [ ] Security audit
- [ ] Performance optimization review
- [ ] Disaster recovery testing
- [ ] Capacity planning review

---

# 📊 Monitoring & Alerts

## Key Metrics to Monitor

| Metric | Threshold | Action |
|--------|-----------|--------|
| CPU Utilization | > 70% | Scale up or optimize |
| Unhealthy Targets | > 0 | Investigate immediately |
| 5xx Error Rate | > 1% | Check application logs |
| Response Time | > 2s | Optimize or scale |
| Cache Hit Rate | < 80% | Review caching strategy |

---

## Alert Response Procedures

### High CPU Alarm
- Check current load  
- Review recent changes  
- Scale up if needed  
- Investigate root cause  

### Unhealthy Targets Alarm
- Check target health status  
- Review application logs  
- Verify security groups  
- Restart instances if needed  

### High Error Rate Alarm
- Check error logs  
- Identify error pattern  
- Check database connectivity  
- Consider rollback  

---

# 📞 Escalation

## When to Escalate
- Complete service outage  
- Security incident  
- Data loss or corruption  
- Unable to resolve after 1 hour  

## Contact Information
- Infrastructure Team: [Add contact]  
- On-Call Engineer: [Add contact]  
- AWS Support: [Add support plan details]  

---

# 📝 Change Log

| Date | Change | Author | Impact |
|------|--------|--------|--------|
| [Date] | Initial deployment | [Name] | - |

**Last Updated:** [Current Date]  
**Runbook Version:** 1.0

