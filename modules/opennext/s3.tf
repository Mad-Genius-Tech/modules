
module "s3_bucket" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "~> 3.15.0"
  bucket        = "${local.name}-assets"
  force_destroy = false
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  versioning = {
    status = "Enabled"
  }
  tags = local.tags
}

resource "aws_s3_bucket_lifecycle_configuration" "assets" {
  bucket = module.s3_bucket.s3_bucket_id
  rule {
    id     = "abort-failed-uploads"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
  rule {
    id     = "clear-versioned-assets"
    status = "Enabled"
    filter {}
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "ONEZONE_IA"
    }
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = module.s3_bucket.s3_bucket_id
  policy = <<EOF
  {
    "Version": "2008-10-17",
    "Id": "PolicyForCloudFrontPrivateContent",
    "Statement": [
        {
            "Sid": "AllowCloudFrontServicePrincipal",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudfront.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": "${module.s3_bucket.s3_bucket_arn}/*",
            "Condition": {
                "StringEquals": {
                  "AWS:SourceArn": "${aws_cloudfront_distribution.website_distribution.arn}"
                }
            }
        }
    ]
  }
  EOF
}

resource "aws_s3_object" "s3_object_placeholder" {
  bucket = module.s3_bucket.s3_bucket_id
  key    = "placeholder.zip"
  source = "${path.module}/placeholder.zip"

  lifecycle {
    ignore_changes = [
      key,
      source,
      etag
    ]
  }
}

module "s3_bucket_lambda" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "~> 3.15.0"
  bucket        = "${local.name}-lambda-builds"
  force_destroy = false
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  versioning = {
    status = "Enabled"
  }
  tags = local.tags
}

resource "aws_s3_object" "s3_lambda_object_placeholder" {
  bucket = module.s3_bucket_lambda.s3_bucket_id
  key    = "placeholder.zip"
  source = "${path.module}/placeholder.zip"

  lifecycle {
    ignore_changes = [
      key,
      source,
      etag
    ]
  }
}