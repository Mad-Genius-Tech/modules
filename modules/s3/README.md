## Optional S3 Inventory

Set `inventory` only on buckets that need a report. Buckets without this object
create no Inventory configuration, preserving existing consumers. An enabled
configuration defaults to an all-versions, daily CSV report with SSE-S3
encryption; set `sse_kms_key_id` to use a customer-managed KMS key instead.

```hcl
s3_buckets = {
  source = {
    inventory = {
      destination_bucket_arn = "arn:aws:s3:::example-inventory-destination"
      destination_prefix     = "source/"
      optional_fields        = ["Size", "StorageClass"]
    }
  }
}
```

The destination bucket and any required delivery policy remain consumer-owned.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.56.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_context"></a> [context](#module\_context) | cloudposse/label/null | ~> 0.25.0 |
| <a name="module_s3_bucket"></a> [s3\_bucket](#module\_s3\_bucket) | terraform-aws-modules/s3-bucket/aws | ~> 3.15.1 |

## Resources

| Name | Type |
|------|------|
| [aws_lambda_permission.lambda_permission](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_s3_bucket_inventory.inventory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_inventory) | resource |
| [aws_s3_bucket_notification.bucket_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.public_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_lambda_function.lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lambda_function) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_org_name"></a> [org\_name](#input\_org\_name) | n/a | `string` | n/a | yes |
| <a name="input_s3_buckets"></a> [s3\_buckets](#input\_s3\_buckets) | A map of s3 buckets to create | <pre>map(object({<br>    create                                = optional(bool)<br>    acl                                   = optional(string)<br>    attach_policy                         = optional(bool)<br>    policy                                = optional(string)<br>    attach_public_policy                  = optional(bool)<br>    attach_public_read_policy             = optional(bool)<br>    attach_deny_insecure_transport_policy = optional(bool)<br>    attach_require_latest_tls_policy      = optional(bool)<br>    attach_elb_log_delivery_policy        = optional(bool)<br>    attach_lb_log_delivery_policy         = optional(bool)<br>    lifecycle_rule = optional(list(object({<br>      id      = optional(string)<br>      prefix  = optional(string)<br>      enabled = optional(bool)<br>      expiration = optional(object({<br>        days                         = optional(number)<br>        date                         = optional(string)<br>        expired_object_delete_marker = optional(bool)<br>      }))<br>      transition = optional(list(object({<br>        days          = optional(number)<br>        date          = optional(string)<br>        storage_class = optional(string)<br>      })))<br>      noncurrent_version_transition = optional(list(object({<br>        days          = optional(number)<br>        storage_class = optional(string)<br>      })))<br>      noncurrent_version_expiration = optional(object({<br>        days = optional(number)<br>      }))<br>      abort_incomplete_multipart_upload_days = optional(number)<br>      tags                                   = optional(map(string))<br>    })))<br>    versioning = optional(object({<br>      enabled    = optional(bool)<br>      mfa_delete = optional(bool)<br>    }))<br>    server_side_encryption_configuration = optional(object({<br>      rule = optional(object({<br>        apply_server_side_encryption_by_default = optional(object({<br>          kms_master_key_id = optional(string)<br>          sse_algorithm     = optional(string)<br>        }))<br>      }))<br>    }))<br>    block_public_acls        = optional(bool)<br>    block_public_policy      = optional(bool)<br>    ignore_public_acls       = optional(bool)<br>    restrict_public_buckets  = optional(bool)<br>    control_object_ownership = optional(bool)<br>    object_ownership         = optional(string)<br>    acceleration_status      = optional(string)<br>    cors_rule = optional(list(object({<br>      allowed_headers = optional(list(string))<br>      allowed_methods = optional(list(string))<br>      allowed_origins = optional(list(string))<br>      expose_headers  = optional(list(string))<br>      max_age_seconds = optional(number)<br>    })))<br>    website = optional(object({<br>      index_document = optional(string, null)<br>      error_document = optional(string, null)<br>      # redirect_all_requests_to = optional(object({<br>      #   host_name = optional(string)<br>      #   protocol  = optional(string)<br>      # }))<br>      # routing_rules = optional(list(object({<br>      #   condition = optional(object({<br>      #     http_error_code_returned_equals = optional(string)<br>      #     key_prefix_equals               = optional(string)<br>      #   }))<br>      #   redirect = optional(object({<br>      #     host_name               = optional(string)<br>      #     http_redirect_code      = optional(string)<br>      #     protocol                = optional(string)<br>      #     replace_key_prefix_with = optional(string)<br>      #     replace_key_with        = optional(string)<br>      #   }))<br>      # })))<br>    }))<br>    lambda_function_name = optional(string)<br>    events_filter = optional(map(object({<br>      lambda        = optional(string)<br>      bucket_events = optional(list(string))<br>      prefix        = optional(string)<br>      suffix        = optional(string)<br>    })))<br>    intelligent_tiering = optional(object({<br>      enabled = optional(bool, false)<br>      transition = optional(list(object({<br>        days          = optional(number)<br>        storage_class = optional(string)<br>      })), [])<br>    }))<br>    inventory = optional(object({<br>      name                     = optional(string, "inventory")<br>      destination_bucket_arn   = string<br>      destination_prefix       = optional(string)<br>      destination_account_id   = optional(string)<br>      included_object_versions = optional(string, "All")<br>      optional_fields          = optional(set(string), [])<br>      frequency                = optional(string, "Daily")<br>      filter_prefix            = optional(string)<br>      sse_kms_key_id           = optional(string)<br>    }))<br>    tags = optional(map(string))<br>  }))</pre> | `{}` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | n/a | `string` | n/a | yes |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | n/a | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | `{}` | no |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_s3_info"></a> [s3\_info](#output\_s3\_info) | n/a |
<!-- END_TF_DOCS -->
