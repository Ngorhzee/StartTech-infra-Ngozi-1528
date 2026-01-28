output "s3_bucket_name" {
    value = aws_s3_bucket.s3_bucket.bucket
  
}
output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.cloudfront_distribution.id
}

output "cloudfront_distribution_arn" {
    value = aws_cloudfront_distribution.cloudfront_distribution.arn
  
}
