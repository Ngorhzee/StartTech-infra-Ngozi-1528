resource "aws_sns_topic" "alarms" {
  name = "${var.project_name}-alarms"
  
  tags = {
    Name        = "${var.project_name}-alarms"
    Environment = "Production"
  }
}
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = "ngoziamolo02@gmail.com"
}
# cloudwatch log group for backend ec2 intances
resource "aws_cloudwatch_log_group" "backend_logs" {
  name              = "/${var.project_name}/backend"
  retention_in_days = 14
}

# cloudwatch log group for frontend
resource "aws_cloudwatch_log_group" "frontend_logs" {
  name              = "/${var.project_name}/frontend"
  retention_in_days = 14
}

 resource "aws_cloudwatch_metric_alarm" "backend_high_cpu" {
  alarm_name          = "${var.project_name}-backend-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
    alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  alarm_description = "High CPU usage on backend EC2 instances"
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "${var.project_name}-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  
  }
    alarm_actions = [aws_sns_topic.alarms.arn]
    ok_actions = [aws_sns_topic.alarms.arn]

  alarm_description = "One or more backend targets are unhealthy"
  
}
