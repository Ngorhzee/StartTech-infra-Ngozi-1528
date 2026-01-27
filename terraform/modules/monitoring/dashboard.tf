resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x    = 0
        y    = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            [ "AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.asg_name ]
          ]
          period = 300
          stat   = "Average"
          title  = "Backend EC2 CPU Utilization"
          region = var.aws_region
          annotations = {
            horizontal = [
              {
                value = 1
                label = "100"
              }
            ]
          }
        }
      },
      {
        type = "metric"
        x    = 12
        y    = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            [ "AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix ]
          ]
          period = 300
          stat   = "Sum"
          title  = "ALB Request Count"
          region = var.aws_region
          annotations = {
            horizontal = [
              {
                value = 1
                label = "100"
              }
            ]
          }
        }
      }
    ]
  })
}
