output "s3bucket_name" {
  value = module.storage.s3_bucket_name

}

output "ecr_repository_url" {
  value = module.compute.ecr_repository_url
}