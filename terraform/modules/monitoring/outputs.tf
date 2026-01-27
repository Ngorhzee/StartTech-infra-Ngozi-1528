output "backend_log_group_name" {
  value = aws_cloudwatch_log_group.backend_logs.name
}

output "frontend_log_group_name" {
  value = aws_cloudwatch_log_group.frontend_logs.name
}
