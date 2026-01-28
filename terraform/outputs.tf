output "s3bucket_name" {
  value = module.storage.s3_bucket_name

}

output "ecr_repository_url" {
  value = module.compute.ecr_repository_url
}

output "project_name" {
  value = var.project_name
  
}
output "asg_name" {
  value = module.compute.asg_name
}

output "alb_arn_suffix" {
  value = module.compute.alb_arn_suffix
}

output "target_group_arn_suffix" {
  value = module.compute.target_group_arn_suffix
}

output "aws_region" {
  value = var.aws_region
}

output "cloudfront_distribution_id" {
  value = module.storage.cloudfront_distribution_id
}

output "cloudfront_distribution_arn" {
  value = module.storage.cloudfront_distribution_arn
}

