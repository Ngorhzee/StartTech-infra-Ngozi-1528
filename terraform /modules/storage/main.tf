resource "aws_s3_bucket" "s3_bucket" {
    bucket = var.s3_bucket_name
    tags = {
      Environment = "Production"
      Terraform = "true"
    }
    
  
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access_block" {
    bucket = aws_s3_bucket.s3_bucket.id
    block_public_acls = false
    block_public_policy = false
    ignore_public_acls = false
    restrict_public_buckets = false
  
}
resource "aws_s3_bucket_website_configuration" "s3_bucket_website_configuration" {
    bucket = aws_s3_bucket.s3_bucket.id
    index_document {
      suffix = "index.html"
    }
   
  
}
resource "aws_s3_bucket_ownership_controls" "s3_bucket_ownership_controls" {
    bucket = aws_s3_bucket.s3_bucket.id
    rule {
        object_ownership = "BucketOwnerPreferred"
    }
  
}
resource "aws_s3_bucket_policy" "bucket_policy" {
    bucket = aws_s3_bucket.s3_bucket.id
    policy = jsonencode({
        "Version":"2012-10-17",
        "Statement":[
            {
                "Sid":"AllowCloudFrontAccess",
                "Effect" : "Allow",
                "Principal":{
                    "AWS":aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn

                }
                 "Action"   : "s3:GetObject"
        "Resource" : "${aws_s3_bucket.s3_bucket.arn}/*"
            }
          
        ]
    })

  
}
resource "aws_s3_bucket_acl" "s3_bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.s3_bucket_ownership_controls,
    aws_s3_bucket_public_access_block.s3_bucket_public_access_block,
  ]

  bucket = aws_s3_bucket.s3_bucket.id
  acl    = "public-read"
}


# cloudfront distribution for frontend
resource "aws_cloudfront_distribution" "cloudfront_distribution" {
origin{
    domain_name = aws_s3_bucket.s3_bucket.bucket_regional_domain_name
    origin_id = var.origin_id
    connection_attempts = 3
    connection_timeout = 10
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
}
viewer_certificate {
 cloudfront_default_certificate = true
  ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
}
default_cache_behavior {
    cached_methods = [ "GET", "HEAD" ]
    target_origin_id = var.origin_id
    allowed_methods = [ "GET", "HEAD" ]
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    forwarded_values {
      cookies {
        forward = "none"
      }
      query_string = false
    }
    
  
}
restrictions {
  geo_restriction {
    restriction_type = "none"
  }
}
default_root_object = "index.html"

enabled = true
tags = {
  Name = "starttech-frontend-cloudfront-distribution"
  Environment = "Production"
}
}


resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "starttech-frontend-cloudfront-origin-access-identity"

  
}
