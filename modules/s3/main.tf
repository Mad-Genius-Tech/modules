locals {
  default_settings = {
    acl                       = null
    attach_policy                         = false
    attach_public_read_policy             = false
    policy                                = null
    attach_public_policy                  = false
    attach_deny_insecure_transport_policy = false
    attach_require_latest_tls_policy      = false
    attach_elb_log_delivery_policy        = false
    attach_lb_log_delivery_policy         = false
    acceleration_status       = null
    versioning = {
      status = "Enabled"
    }
    lifecycle_rule = [
      {
        id                                     = "abort-failed-uploads"
        enabled                                = true
        abort_incomplete_multipart_upload_days = 1
      },
      {
        id      = "clear-versioned-assets"
        enabled = true
        # noncurrent_version_transition = [
        #   {
        #     days          = 30
        #     storage_class = "ONEZONE_IA"
        #   }
        # ]
        noncurrent_version_expiration = {
          days = 7
        }
      }
    ]
    intelligent_tiering = [
      {
        id      = "IntelligentTieringRule"
        enabled = true
        transition = [
          {
            days          = 7
            storage_class = "INTELLIGENT_TIERING"
          }
        ]
      }
    ]
    block_public_acls        = true
    block_public_policy      = true
    ignore_public_acls       = true
    restrict_public_buckets  = true
    cors_rule                = []
    control_object_ownership = false
    object_ownership         = "BucketOwnerEnforced"
    lambda_function_name     = ""
    bucket_events            = ["s3:ObjectCreated:*"]
    events_filter            = {}
    server_side_encryption_configuration = {
      rule = {
        apply_server_side_encryption_by_default = {
          sse_algorithm = "AES256"
        }
      }
    }
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
        lifecycle_rule = [
          {
            id                                     = "abort-failed-uploads"
            enabled                                = true
            abort_incomplete_multipart_upload_days = 1
          },
          {
            id      = "clear-versioned-assets"
            enabled = true
            # noncurrent_version_transition = [
            #   {
            #     days          = 30
            #     storage_class = "STANDARD_IA"
            #   },
            #   {
            #     days          = 60
            #     storage_class = "ONEZONE_IA"
            #   }
            # ]
            noncurrent_version_expiration = {
              days = 7
            }
          }
        ]
        intelligent_tiering = [
          {
            id      = "IntelligentTieringRule"
            enabled = true
            transition = [
              {
                days          = 30
                storage_class = "INTELLIGENT_TIERING"
              }
            ]
          }
        ]
    })
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  lifecycle_rule_defaults = [
    for rule in jsondecode(jsonencode(local.merged_default_settings.lifecycle_rule)) : {
      for rule_key, rule_value in rule : rule_key => rule_value if rule_value != null
    }
  ]

  lifecycle_rule_defaults_by_id = {
    for rule in local.lifecycle_rule_defaults : rule.id => rule if try(rule.id, null) != null
  }

  lifecycle_rule_custom_by_bucket = {
    for k, v in var.s3_buckets : k => [
      for rule in jsondecode(jsonencode(coalesce(try(v.lifecycle_rule, null), []))) : {
        for rule_key, rule_value in rule : rule_key => rule_value if rule_value != null
      }
    ]
  }

  lifecycle_rule_by_bucket = {
    for k, custom_rules in local.lifecycle_rule_custom_by_bucket : k => concat(
      [
        for default_rule in local.lifecycle_rule_defaults :
        try(
          lookup(
            merge(local.lifecycle_rule_defaults_by_id, {
              for rule in custom_rules : rule.id => rule if try(rule.id, null) != null
            }),
            default_rule.id,
            default_rule
          ),
          default_rule
        )
      ],
      [
        for custom_rule in custom_rules : custom_rule if try(custom_rule.id, null) == null
      ],
      [
        for custom_id, custom_rule in {
          for rule in custom_rules : rule.id => rule if try(rule.id, null) != null
        } : custom_rule if !contains(keys(local.lifecycle_rule_defaults_by_id), custom_id)
      ]
    )
  }

  s3_buckets_map = {
    for k, v in var.s3_buckets : k => {
      "identifier"                           = "${module.context.id}-${k}"
      "create"                               = coalesce(lookup(v, "create", null), true)
      "acl"                                  = try(coalesce(lookup(v, "acl", null), local.merged_default_settings.acl), local.merged_default_settings.acl)
      "acceleration_status"                  = try(coalesce(lookup(v, "acceleration_status", null), local.merged_default_settings.acceleration_status), local.merged_default_settings.acceleration_status)
      "attach_policy"                        = try(coalesce(lookup(v, "attach_policy", null), lookup(v, "attach_public_read_policy", local.default_settings.attach_public_read_policy)), false) ? true : coalesce(lookup(v, "attach_policy", null), local.default_settings.attach_policy)
      "attach_public_read_policy"            = coalesce(lookup(v, "attach_public_read_policy", null), local.default_settings.attach_public_read_policy)
      "attach_public_policy"                 = coalesce(lookup(v, "attach_public_policy", null), local.default_settings.attach_public_policy)
      "attach_deny_insecure_transport_policy" = coalesce(lookup(v, "attach_deny_insecure_transport_policy", null), local.default_settings.attach_deny_insecure_transport_policy)
      "attach_require_latest_tls_policy"      = coalesce(lookup(v, "attach_require_latest_tls_policy", null), local.default_settings.attach_require_latest_tls_policy)
      "attach_elb_log_delivery_policy"        = coalesce(lookup(v, "attach_elb_log_delivery_policy", null), local.default_settings.attach_elb_log_delivery_policy)
      "attach_lb_log_delivery_policy"         = coalesce(lookup(v, "attach_lb_log_delivery_policy", null), local.default_settings.attach_lb_log_delivery_policy)
      "policy"                               = try(coalesce(lookup(v, "policy", null), local.merged_default_settings.policy), local.merged_default_settings.policy)
      "lifecycle_rule"                       = local.lifecycle_rule_by_bucket[k]
      "versioning"                           = merge(coalesce(lookup(v, "versioning", null), {}), local.default_settings.versioning)
      "server_side_encryption_configuration" = merge(coalesce(lookup(v, "server_side_encryption_configuration", null), {}), local.default_settings.server_side_encryption_configuration)
      "block_public_acls"                    = coalesce(lookup(v, "block_public_acls", null), local.default_settings.block_public_acls)
      "block_public_policy"                  = coalesce(lookup(v, "block_public_policy", null), local.default_settings.block_public_policy)
      "ignore_public_acls"                   = coalesce(lookup(v, "ignore_public_acls", null), local.default_settings.ignore_public_acls)
      "restrict_public_buckets"              = coalesce(lookup(v, "restrict_public_buckets", null), local.default_settings.restrict_public_buckets)
      "cors_rule"                            = concat(try(coalesce(lookup(v, "cors_rule", null), local.merged_default_settings.cors_rule), local.merged_default_settings.cors_rule), local.merged_default_settings.cors_rule)
      "website"                              = v.website != null ? { for k, v in v.website : k => v if v != null } : {}
      "control_object_ownership"             = coalesce(lookup(v, "control_object_ownership", null), local.default_settings.control_object_ownership)
      "object_ownership"                     = coalesce(lookup(v, "object_ownership", null), local.default_settings.object_ownership)
      "lambda_function_name"                 = try(coalesce(lookup(v, "lambda_function_name", null), local.default_settings.lambda_function_name), local.default_settings.lambda_function_name)
      "events_filter"                        = try(coalesce(lookup(v, "events_filter", null), local.default_settings.events_filter), local.default_settings.events_filter)
      "lifecycle_rules" = concat(
        local.lifecycle_rule_by_bucket[k],
        try(v.intelligent_tiering.enabled, false) ? local.merged_default_settings.intelligent_tiering : []
      )
    } if coalesce(lookup(v, "create", null), true)
  }
}

locals {
  events_map = merge([
    for k, v in local.s3_buckets_map : {
      for event in keys(v.events_filter) : "${k}|${event}" => v.events_filter[event]
    } if length(v.events_filter) > 0
  ]...)
}



data "aws_lambda_function" "lambda_function" {
  for_each      = local.events_map
  function_name = each.value.lambda
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  for_each = { for k, v in local.s3_buckets_map : k => v if length(v.events_filter) > 0 }
  bucket   = module.s3_bucket[each.key].s3_bucket_id
  dynamic "lambda_function" {
    for_each = local.events_map
    content {
      lambda_function_arn = data.aws_lambda_function.lambda_function[lambda_function.key].arn
      events              = lambda_function.value.bucket_events
      filter_prefix       = lambda_function.value.prefix
      filter_suffix       = lambda_function.value.suffix
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  bucket_lambda_list = {
    for k, v in local.s3_buckets_map : k => distinct([
      for i in values(v.events_filter) : i.lambda
    ]) if length(v.events_filter) > 0
  }

  bucket_lambda_map = merge([
    for bucket, lambdas in local.bucket_lambda_list : zipmap(
      [for lambda in lambdas : "${bucket}|${lambda}"],
      lambdas
    )
  ]...)
}

resource "aws_lambda_permission" "lambda_permission" {
  for_each      = local.bucket_lambda_map
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  principal     = "s3.amazonaws.com"
  function_name = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${each.value}"
  source_arn    = module.s3_bucket[split("|", each.key)[0]].s3_bucket_arn
}

module "s3_bucket" {
  for_each                             = local.s3_buckets_map
  source                               = "terraform-aws-modules/s3-bucket/aws"
  version                              = "~> 3.15.1"
  create_bucket                        = each.value.create
  bucket                               = each.key
  acl                                  = each.value.acl
  acceleration_status                  = each.value.acceleration_status
  attach_policy                         = each.value.attach_policy
  policy                                = each.value.attach_public_read_policy ? data.aws_iam_policy_document.public_read[each.key].json : each.value.policy
  attach_public_policy                  = each.value.attach_public_policy
  attach_deny_insecure_transport_policy = each.value.attach_deny_insecure_transport_policy
  attach_require_latest_tls_policy      = each.value.attach_require_latest_tls_policy
  attach_elb_log_delivery_policy        = each.value.attach_elb_log_delivery_policy
  attach_lb_log_delivery_policy         = each.value.attach_lb_log_delivery_policy
  lifecycle_rule                       = each.value.lifecycle_rules
  versioning                           = each.value.versioning
  server_side_encryption_configuration = each.value.server_side_encryption_configuration
  block_public_acls                    = each.value.block_public_acls
  block_public_policy                  = each.value.block_public_policy
  ignore_public_acls                   = each.value.ignore_public_acls
  restrict_public_buckets              = each.value.restrict_public_buckets
  cors_rule                            = each.value.cors_rule
  website                              = each.value.website
  control_object_ownership             = each.value.control_object_ownership
  object_ownership                     = each.value.object_ownership
  tags                                 = local.tags
}

data "aws_iam_policy_document" "public_read" {
  for_each = local.s3_buckets_map
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${each.key}/*",
    ]
  }
}
