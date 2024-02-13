locals {
  name         = module.context.id
  s3_origin_id = "${local.name}-s3-origin"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host_header" {
  name = "Managed-AllViewerExceptHostHeader"
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

data "aws_s3_bucket" "static_s3_bucket" {
  bucket = var.static_s3_bucket
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = data.aws_s3_bucket.static_s3_bucket.id
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
            "Resource": "${data.aws_s3_bucket.static_s3_bucket.arn}/*",
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

resource "aws_cloudfront_origin_access_control" "s3_origin_access_control" {
  name                              = "${local.name}-s3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_response_headers_policy" "response_headers_policy" {
  name    = "${local.name}-response-headers-policy"
  comment = "${local.name} Response Headers Policy"
  cors_config {
    origin_override                  = true
    access_control_allow_credentials = false
    access_control_allow_headers {
      items = ["*"]
    }
    access_control_allow_methods {
      items = ["ALL"]
    }
    access_control_allow_origins {
      items = ["*"]
    }
  }
  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      override                   = true
      preload                    = true
    }
  }
}

resource "aws_cloudfront_function" "subdomain_redirect" {
  name    = "${local.name}-subdomain-redirect"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = <<EOF
    function handler(event) {
      var request = event.request;
      var host = request.headers.host.value;
      var subdomain = host.split('.')[0];
      if (request.uri === '/') {
          request.uri = '/' + subdomain + '/index.html';
      } else {
          request.uri = '/' + subdomain + request.uri;
      }
      return request;
    }
  EOF
}

# https://github.com/sst/sst/blob/master/packages/sst/src/constructs/SsrSite.ts#L790
resource "aws_cloudfront_distribution" "website_distribution" {
  enabled             = true
  comment             = "CloudFront for ${local.name}"
  is_ipv6_enabled     = true
  aliases             = var.domain_names
  price_class         = "PriceClass_100"
  http_version        = "http2"
  default_root_object = "index.html"

  # logging_config {
  #   include_cookies = false
  #   bucket          = module.cloudfront_logs.logs_s3_bucket.bucket_regional_domain_name
  #   prefix = one(var.domain_names)
  # }

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
    domain_name              = data.aws_s3_bucket.static_s3_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_origin_access_control.id
    # origin_path              = "/"
    origin_id = local.s3_origin_id
  }

  # dynamic "ordered_cache_behavior" {
  #   for_each = local.subdomains
  #   content {
  #     target_origin_id           = local.s3_origin_id
  #     path_pattern               = ordered_cache_behavior.value.s3_bucket_path
  #     viewer_protocol_policy     = "redirect-to-https"
  #     allowed_methods            = ["GET", "HEAD", "OPTIONS"]
  #     cached_methods             = ["GET", "HEAD", "OPTIONS"]
  #     compress                   = true
  #     cache_policy_id            = data.aws_cloudfront_cache_policy.caching_optimized.id
  #     response_headers_policy_id = aws_cloudfront_response_headers_policy.response_headers_policy.id
  #     function_association {
  #       event_type   = "viewer-request"
  #       function_arn = aws_cloudfront_function.subdomain_redirect.arn
  #     }
  #   }
  # }
  default_cache_behavior {
    target_origin_id           = local.s3_origin_id
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    compress                   = true
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_optimized.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.response_headers_policy.id
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.subdomain_redirect.arn
    }
  }
}
