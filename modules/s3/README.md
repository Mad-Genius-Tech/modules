<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_context"></a> [context](#module\_context) | cloudposse/label/null | ~> 0.25.0 |
| <a name="module_s3_bucket"></a> [s3\_bucket](#module\_s3\_bucket) | terraform-aws-modules/s3-bucket/aws | ~> 3.15.1 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy_document.public_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_org_name"></a> [org\_name](#input\_org\_name) | n/a | `string` | n/a | yes |
| <a name="input_s3_buckets"></a> [s3\_buckets](#input\_s3\_buckets) | A map of s3 buckets to create | <pre>map(object({<br>    create                    = optional(bool)<br>    acl                       = optional(string)<br>    attach_policy             = optional(bool)<br>    policy                    = optional(string)<br>    attach_public_policy      = optional(bool)<br>    attach_public_read_policy = optional(bool)<br>    lifecycle_rule = optional(list(object({<br>      id      = optional(string)<br>      prefix  = optional(string)<br>      enabled = optional(bool)<br>      expiration = optional(object({<br>        days                         = optional(number)<br>        date                         = optional(string)<br>        expired_object_delete_marker = optional(bool)<br>      }))<br>      transition = optional(list(object({<br>        days          = optional(number)<br>        date          = optional(string)<br>        storage_class = optional(string)<br>      })))<br>      noncurrent_version_transition = optional(list(object({<br>        days          = optional(number)<br>        storage_class = optional(string)<br>      })))<br>      noncurrent_version_expiration = optional(object({<br>        days = optional(number)<br>      }))<br>      abort_incomplete_multipart_upload_days = optional(number)<br>      tags                                   = optional(map(string))<br>    })))<br>    versioning = optional(object({<br>      enabled    = optional(bool)<br>      mfa_delete = optional(bool)<br>    }))<br>    server_side_encryption_configuration = optional(object({<br>      rule = optional(object({<br>        apply_server_side_encryption_by_default = optional(object({<br>          kms_master_key_id = optional(string)<br>          sse_algorithm     = optional(string)<br>        }))<br>      }))<br>    }))<br>    block_public_acls        = optional(bool)<br>    block_public_policy      = optional(bool)<br>    ignore_public_acls       = optional(bool)<br>    restrict_public_buckets  = optional(bool)<br>    control_object_ownership = optional(bool)<br>    object_ownership         = optional(string)<br>    cors_rule = optional(list(object({<br>      allowed_headers = optional(list(string))<br>      allowed_methods = optional(list(string))<br>      allowed_origins = optional(list(string))<br>      expose_headers  = optional(list(string))<br>      max_age_seconds = optional(number)<br>    })))<br>    website = optional(object({<br>      index_document = optional(string)<br>      # error_document = optional(string)<br>      # redirect_all_requests_to = optional(object({<br>      #   host_name = optional(string)<br>      #   protocol  = optional(string)<br>      # }))<br>      # routing_rules = optional(list(object({<br>      #   condition = optional(object({<br>      #     http_error_code_returned_equals = optional(string)<br>      #     key_prefix_equals               = optional(string)<br>      #   }))<br>      #   redirect = optional(object({<br>      #     host_name               = optional(string)<br>      #     http_redirect_code      = optional(string)<br>      #     protocol                = optional(string)<br>      #     replace_key_prefix_with = optional(string)<br>      #     replace_key_with        = optional(string)<br>      #   }))<br>      # })))<br>    }))<br>    tags = optional(map(string))<br>  }))</pre> | `{}` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | n/a | `string` | n/a | yes |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | n/a | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | `{}` | no |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_s3_info"></a> [s3\_info](#output\_s3\_info) | n/a |
<!-- END_TF_DOCS -->