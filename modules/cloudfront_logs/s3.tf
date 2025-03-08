locals {
  s3_bucket = var.s3_bucket != "" ? var.s3_bucket : "${local.name}-accesslogs"
}

resource "aws_s3_bucket" "cloudfront_access_logs" {
  count  = var.s3_bucket == "" ? 1 : 0
  bucket = local.s3_bucket
  lifecycle_rule {
    id      = "ExpireAthenaQueryResults"
    enabled = true
    prefix  = "athena-query-results/"
    expiration {
      days = 1
    }
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudfront_access_logs" {
  count                   = var.s3_bucket == "" ? 1 : 0
  bucket                  = join("", aws_s3_bucket.cloudfront_access_logs[*].id)
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cloudfront_access_logs" {
  count  = var.s3_bucket == "" ? 1 : 0
  bucket = join("", aws_s3_bucket.cloudfront_access_logs[*].id)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          join("", aws_s3_bucket.cloudfront_access_logs[*].arn),
          "${join("", aws_s3_bucket.cloudfront_access_logs[*].arn)}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
