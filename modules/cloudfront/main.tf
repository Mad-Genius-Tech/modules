
locals {

  default_settings = {
    enabled                                = true
    price_class                            = "PriceClass_100"
    s3_bucket                              = ""
    wildcard_domain                        = true
    default_cache_behavior_allowed_methods = ["GET", "HEAD"]
    viewer_protocol_policy                 = "redirect-to-https"
    origin_request_policy                  = ""
    response_headers_policy                = ""
    enable_upload_to_s3_origin             = false
    custom_error_response                  = [{}]
    origin_domain_name                     = ""
    default_root_object                    = "index.html"
    custom_origin_config = {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols   = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
        price_class = "PriceClass_All"
    })
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  cloudfront_map = {
    for k, v in var.cloudfront : k => {
      "identifier"                             = "${module.context.id}-${k}"
      "create"                                 = coalesce(lookup(v, "create", null), true)
      "aliases"                                = distinct(compact(concat(coalesce(lookup(v, "aliases", []), []), [v.domain_name])))
      "enabled"                                = try(coalesce(lookup(v, "enabled", null), local.merged_default_settings.enabled), local.merged_default_settings.enabled)
      "s3_bucket"                              = try(coalesce(lookup(v, "s3_bucket", null), local.merged_default_settings.s3_bucket), local.merged_default_settings.s3_bucket)
      "wildcard_domain"                        = try(coalesce(lookup(v, "wildcard_domain", null), local.merged_default_settings.wildcard_domain), local.merged_default_settings.wildcard_domain)
      "price_class"                            = try(coalesce(lookup(v, "price_class", null), local.merged_default_settings.price_class), local.merged_default_settings.price_class)
      "default_cache_behavior_allowed_methods" = try(coalesce(lookup(v, "default_cache_behavior_allowed_methods", null), local.merged_default_settings.default_cache_behavior_allowed_methods), local.merged_default_settings.default_cache_behavior_allowed_methods)
      "domain_name"                            = v.domain_name
      "origin_request_policy"                  = try(coalesce(lookup(v, "origin_request_policy", null), local.merged_default_settings.origin_request_policy), local.merged_default_settings.origin_request_policy)
      "response_headers_policy"                = try(coalesce(lookup(v, "response_headers_policy", null), local.merged_default_settings.response_headers_policy), local.merged_default_settings.response_headers_policy)
      "custom_error_response"                  = coalesce(lookup(v, "custom_error_response", null), local.merged_default_settings.custom_error_response)
      "viewer_protocol_policy"                 = try(coalesce(lookup(v, "viewer_protocol_policy", null), local.merged_default_settings.viewer_protocol_policy), local.merged_default_settings.viewer_protocol_policy)
      "origin_domain_name"                     = try(coalesce(lookup(v, "origin_domain_name", null), local.merged_default_settings.origin_domain_name), local.merged_default_settings.origin_domain_name)
      "custom_origin_config"                   = { for k, v in merge(local.merged_default_settings.custom_origin_config, coalesce(lookup(v, "custom_origin_config", null), local.merged_default_settings.custom_origin_config)) : k => v != null ? v : local.merged_default_settings.custom_origin_config[k] }
      "enable_upload_to_s3_origin"             = try(coalesce(lookup(v, "enable_upload_to_s3_origin", null), local.merged_default_settings.enable_upload_to_s3_origin), local.merged_default_settings.enable_upload_to_s3_origin)
    } if coalesce(lookup(v, "create", null), true)
  }
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

data "aws_acm_certificate" "wildcard" {
  for_each = { for k, v in local.cloudfront_map : k => v if v.create && v.wildcard_domain }
  domain   = join(".", slice(split(".", each.value.domain_name), 1, length(split(".", each.value.domain_name))))
  statuses = ["ISSUED"]
  provider = aws.us-east-1
}

data "aws_acm_certificate" "non_wildcard" {
  for_each = { for k, v in local.cloudfront_map : k => v if v.create && !v.wildcard_domain }
  domain   = each.value.domain_name
  statuses = ["ISSUED"]
  provider = aws.us-east-1
}

module "cloudfront" {
  source                        = "terraform-aws-modules/cloudfront/aws"
  version                       = "~> 3.2.1"
  for_each                      = local.cloudfront_map
  aliases                       = each.value.aliases
  comment                       = each.value.s3_bucket != "" ? "CloudFront for S3 bucket ${each.value.s3_bucket}" : "CloudFront for domain ${each.value.origin_domain_name}"
  enabled                       = each.value.enabled
  price_class                   = each.value.price_class
  default_root_object           = each.value.default_root_object
  create_origin_access_identity = false
  origin_access_identities = {
    "${each.value.s3_bucket}" = each.value.s3_bucket
  }
  create_origin_access_control = each.value.s3_bucket != "" ? true : false
  origin_access_control = each.value.s3_bucket != "" ? {
    "${each.value.s3_bucket}" = {
      description      = "CloudFront access to S3 ${each.value.s3_bucket}"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  } : {}

  origin = merge(
    each.value.s3_bucket != "" ? {
      "${each.value.s3_bucket}" = {
        domain_name           = data.aws_s3_bucket.s3_bucket[each.key].bucket_regional_domain_name
        origin_access_control = each.value.s3_bucket
      }
    } : {},
    each.value.origin_domain_name != "" ? {
      "${each.value.origin_domain_name}" = {
        domain_name          = each.value.origin_domain_name
        custom_origin_config = each.value.custom_origin_config
      }
    } : {}
  )

  default_cache_behavior = {
    target_origin_id           = each.value.s3_bucket != "" ? each.value.s3_bucket : each.value.origin_domain_name
    viewer_protocol_policy     = each.value.viewer_protocol_policy
    allowed_methods            = each.value.default_cache_behavior_allowed_methods
    cached_methods             = contains(each.value.default_cache_behavior_allowed_methods, "OPTIONS") ? ["GET", "HEAD", "OPTIONS"] : ["GET", "HEAD"]
    cache_methods              = ["GET", "HEAD"]
    compress                   = true
    use_forwarded_values       = false
    cache_policy_id            = data.aws_cloudfront_cache_policy.cache_policy.id
    origin_request_policy_id   = length(try(coalesce(each.value.origin_request_policy, ""), "")) > 0 ? data.aws_cloudfront_origin_request_policy.request_policy[each.key].id : null
    response_headers_policy_id = length(try(coalesce(each.value.response_headers_policy, ""), "")) > 0 ? data.aws_cloudfront_response_headers_policy.response_policy[each.key].id : null
  }

  viewer_certificate = {
    acm_certificate_arn      = each.value.wildcard_domain ? data.aws_acm_certificate.wildcard[each.key].arn : data.aws_acm_certificate.non_wildcard[each.key].arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  custom_error_response = each.value.enable_upload_to_s3_origin ? [{
    error_code            = 403
    error_caching_min_ttl = 5
  }] : each.value.custom_error_response

  tags = local.tags
}

data "aws_cloudfront_cache_policy" "cache_policy" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "request_policy" {
  for_each = { for k, v in local.cloudfront_map : k => v if length(try(coalesce(v.origin_request_policy, ""), "")) > 0 }
  name     = each.value.origin_request_policy
}

data "aws_cloudfront_response_headers_policy" "response_policy" {
  for_each = { for k, v in local.cloudfront_map : k => v if length(try(coalesce(v.response_headers_policy, ""), "")) > 0 }
  name     = each.value.response_headers_policy
}

data "aws_s3_bucket" "s3_bucket" {
  for_each = { for k, v in local.cloudfront_map : k => v if length(try(coalesce(v.s3_bucket, ""), "")) > 0 }
  bucket   = each.value.s3_bucket
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  for_each = { for k, v in local.cloudfront_map : k => v if length(try(coalesce(v.s3_bucket, ""), "")) > 0 }
  bucket   = data.aws_s3_bucket.s3_bucket[each.key].id
  policy   = data.aws_iam_policy_document.bucket_policy[each.key].json
}

data "aws_iam_policy_document" "bucket_policy" {
  for_each = { for k, v in local.cloudfront_map : k => v if length(try(coalesce(v.s3_bucket, ""), "")) > 0 }
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = each.value.enable_upload_to_s3_origin ? [
      "s3:GetObject",
      "s3:PutObject"
      ] : [
      "s3:GetObject"
    ]

    resources = [
      "${data.aws_s3_bucket.s3_bucket[each.key].arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.cloudfront[each.key].cloudfront_distribution_arn]
    }
  }
}
