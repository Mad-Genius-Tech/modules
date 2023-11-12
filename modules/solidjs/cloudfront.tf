locals {
  name = module.context.id
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_cloudfront_origin_access_control" "s3_origin_access_control" {
  name                              = "${local.name}-s3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host_header" {
  name = "Managed-AllViewerExceptHostHeader"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

data "aws_acm_certificate" "wildcard" {
  count    = var.wildcard_domain ? 1 : 0
  domain   = join(".", slice(split(".", var.domain_names[0]), 1, length(split(".", var.domain_names[0]))))
  statuses = ["ISSUED"]
  provider = aws.us-east-1
}

data "aws_acm_certificate" "non_wildcard" {
  count    = var.wildcard_domain ? 0 : 1
  domain   = var.domain_names[0]
  statuses = ["ISSUED"]
  provider = aws.us-east-1
}

locals {
  s3_origin_id                = "${local.name}-s3-origin"
  server_function_origin      = "${local.name}-server-function-origin"
  server_function_domain_name = trimsuffix(trimprefix(module.server.lambda_function_url, "https://"), "/")
}

resource "aws_cloudfront_distribution" "website_distribution" {
  enabled         = true
  comment         = "CloudFront for ${local.name}"
  is_ipv6_enabled = true
  aliases         = var.domain_names
  price_class     = "PriceClass_100"
  http_version    = "http2"

  viewer_certificate {
    acm_certificate_arn      = var.wildcard_domain ? data.aws_acm_certificate.wildcard[0].arn : data.aws_acm_certificate.non_wildcard[0].arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  origin {
    domain_name              = module.s3_bucket.s3_bucket_bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_origin_access_control.id
    origin_id                = local.s3_origin_id
  }

  origin {
    domain_name = local.server_function_domain_name
    origin_id   = local.server_function_origin
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      origin_read_timeout    = 10
    }
  }

  ordered_cache_behavior {
    path_pattern           = "images/*"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = local.s3_origin_id
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }
  ordered_cache_behavior {
    path_pattern           = "assets/*"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = local.s3_origin_id
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }
  ordered_cache_behavior {
    path_pattern           = "*.css"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = local.s3_origin_id
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }
  ordered_cache_behavior {
    path_pattern           = "*.ico"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = local.s3_origin_id
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }
  ordered_cache_behavior {
    path_pattern           = "*.json"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = local.s3_origin_id
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = local.server_function_origin
    compress               = true
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_disabled.id
    viewer_protocol_policy = "redirect-to-https"
  }

}
