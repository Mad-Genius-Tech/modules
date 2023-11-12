locals {
  name = module.context.id
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_cloudfront_function" "x_forwarded_host" {
  name    = "${local.name}-x-forwarded-host"
  runtime = "cloudfront-js-1.0"
  publish = true
  code    = <<EOF
function handler(event) {
  var request = event.request;
  request.headers["x-forwarded-host"] = request.headers.host;
  return request;
}
EOF
}

resource "aws_cloudfront_origin_access_control" "s3_origin_access_control" {
  name                              = "${local.name}-s3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# https://github.com/sst/sst/blob/master/packages/sst/src/constructs/NextjsSite.ts#L120-L133
# https://github.com/sst/sst/blob/master/packages/sst/src/constructs/SsrSite.ts#L1345
resource "aws_cloudfront_cache_policy" "cache_policy" {
  name        = "${local.name}-cache-policy"
  comment     = "Server response cache policy for ${local.name}"
  default_ttl = 0
  min_ttl     = 0
  max_ttl     = 31536000 # 365*24*60*60
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["next-url", "rsc", "next-router-prefetch", "next-router-state-tree", "accept"]
        # ["accept", "rsc", "next-router-prefetch", "next-router-state-tree", "x-prerender-revalidate"],
      }
    }
    query_strings_config {
      query_string_behavior = "all"
    }
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

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

locals {
  s3_origin_id                = "${local.name}-s3-origin"
  image_function_origin       = "${local.name}-image-function-origin"
  server_function_origin      = "${local.name}-server-function-origin"
  image_function_domain_name  = trimsuffix(trimprefix(module.image_optimisation.lambda_function_url, "https://"), "/")
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
    origin_path              = "/_assets"
    origin_id                = local.s3_origin_id
  }
  origin {
    domain_name = local.image_function_domain_name
    origin_id   = local.image_function_origin
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
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
    path_pattern             = "api/*"
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"]
    cached_methods           = ["GET", "HEAD", "OPTIONS"]
    target_origin_id         = local.server_function_origin
    cache_policy_id          = aws_cloudfront_cache_policy.cache_policy.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header.id
    compress                 = true
    viewer_protocol_policy   = "redirect-to-https"
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.x_forwarded_host.arn
    }
  }
  ordered_cache_behavior {
    path_pattern             = "_next/data/*"
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"]
    cached_methods           = ["GET", "HEAD", "OPTIONS"]
    target_origin_id         = local.server_function_origin
    cache_policy_id          = aws_cloudfront_cache_policy.cache_policy.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header.id
    compress                 = true
    viewer_protocol_policy   = "redirect-to-https"
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.x_forwarded_host.arn
    }
  }
  ordered_cache_behavior {
    path_pattern             = "_next/image*"
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"]
    cached_methods           = ["GET", "HEAD", "OPTIONS"]
    target_origin_id         = local.image_function_origin
    cache_policy_id          = aws_cloudfront_cache_policy.cache_policy.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header.id
    compress                 = true
    viewer_protocol_policy   = "redirect-to-https"
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.x_forwarded_host.arn
    }
  }
  ordered_cache_behavior {
    path_pattern           = "BUILD_ID"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = local.s3_origin_id
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }
  ordered_cache_behavior {
    path_pattern           = "_next/*"
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
    path_pattern           = "favicon.ico"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = local.s3_origin_id
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }
  ordered_cache_behavior {
    path_pattern           = "next.svg"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = local.s3_origin_id
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }
  ordered_cache_behavior {
    path_pattern           = "vercel.svg"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = local.s3_origin_id
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }
  default_cache_behavior {
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"]
    cached_methods           = ["GET", "HEAD", "OPTIONS"]
    target_origin_id         = local.server_function_origin
    cache_policy_id          = aws_cloudfront_cache_policy.cache_policy.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header.id
    compress                 = true
    viewer_protocol_policy   = "redirect-to-https"
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.x_forwarded_host.arn
    }
  }

}
