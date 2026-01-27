output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}

output "backend_sg_id" {
  value = aws_security_group.backend_sg.id
}

output "asg_name" {
  value = aws_autoscaling_group.backend_asg.name
}

output "alb_arn_suffix" {
  value = aws_lb.app_alb.arn_suffix
}

output "target_group_arn_suffix" {
  value = aws_lb_target_group.backend_tg.arn_suffix
}

output "ecr_repository_url" {
  value = aws_ecr_repository.backend_repo.repository_url
}