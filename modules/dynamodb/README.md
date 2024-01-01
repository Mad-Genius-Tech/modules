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
| <a name="module_dynamodb_table"></a> [dynamodb\_table](#module\_dynamodb\_table) | terraform-aws-modules/dynamodb-table/aws | ~> 4.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.dynamodb_fullaccess](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dynamodb"></a> [dynamodb](#input\_dynamodb) | n/a | <pre>map(object({<br>    table_name   = string<br>    billing_mode = optional(string)<br>    table_class  = optional(string)<br>    hash_key     = string<br>    range_key    = optional(string)<br>    attributes = list(object({<br>      name = string<br>      type = string<br>    }))<br>    read_capacity                  = optional(number)<br>    write_capacity                 = optional(number)<br>    server_side_encryption_enabled = optional(bool)<br>    deletion_protection_enabled    = optional(bool)<br>    global_secondary_indexes = optional(list(object({<br>      name                                  = string<br>      hash_key                              = string<br>      range_key                             = optional(string)<br>      write_capacity                        = optional(number)<br>      read_capacity                         = optional(number)<br>      projection_type                       = optional(string)<br>      non_key_attributes                    = optional(list(string))<br>      server_side_encryption_enabled        = optional(bool)<br>      stream_enabled                        = optional(bool)<br>      stream_view_type                      = optional(string)<br>      projection_non_key_attributes         = optional(list(string))<br>      projection_include                    = optional(bool)<br>      projection_include_type               = optional(string)<br>      projection_include_non_key_attributes = optional(list(string))<br>    })))<br>    ignore_changes_global_secondary_index = optional(bool)<br>    autoscaling_read_enabled              = optional(bool)<br>    autoscaling_read_scale_in_cooldown    = optional(number)<br>    autoscaling_read_scale_out_cooldown   = optional(number)<br>    autoscaling_read_target_value         = optional(number)<br>    autoscaling_read_max_capacity         = optional(number)<br>    autoscaling_write_enabled             = optional(bool)<br>    autoscaling_write_scale_in_cooldown   = optional(number)<br>    autoscaling_write_scale_out_cooldown  = optional(number)<br>    autoscaling_write_target_value        = optional(number)<br>    autoscaling_write_max_capacity        = optional(number)<br>    tags                                  = optional(map(string))<br>    autoscaling_indexes = optional(map(object({<br>      read_max_capacity  = optional(number)<br>      read_min_capacity  = optional(number)<br>      write_max_capacity = optional(number)<br>      write_min_capacity = optional(number)<br>    })))<br>    point_in_time_recovery_enabled = optional(bool)<br>    stream_enabled                 = optional(bool)<br>    stream_view_type               = optional(string)<br>    ttl_enabled                    = optional(bool)<br>    ttl_attribute_name             = optional(string)<br>  }))</pre> | n/a | yes |
| <a name="input_org_name"></a> [org\_name](#input\_org\_name) | n/a | `string` | n/a | yes |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | n/a | `string` | n/a | yes |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | n/a | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | `{}` | no |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dynamodb_fullaccess_policy"></a> [dynamodb\_fullaccess\_policy](#output\_dynamodb\_fullaccess\_policy) | n/a |
| <a name="output_dynamodb_info"></a> [dynamodb\_info](#output\_dynamodb\_info) | n/a |
<!-- END_TF_DOCS -->