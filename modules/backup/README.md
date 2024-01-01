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

## Resources

| Name | Type |
|------|------|
| [aws_backup_plan.backup_plan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_plan) | resource |
| [aws_backup_selection.selection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_selection) | resource |
| [aws_backup_vault.vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_iam_role.backup_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_backup_plans"></a> [backup\_plans](#input\_backup\_plans) | n/a | <pre>map(object({<br>    create               = optional(bool)<br>    backup_resources     = optional(list(string))<br>    not_backup_resources = optional(list(string))<br>    selection_tag = optional(list(object({<br>      type  = optional(string)<br>      key   = optional(string)<br>      value = optional(string)<br>    })))<br>    condition = optional(object({<br>      string_equals = optional(list(object({<br>        key   = string<br>        value = string<br>      })), [])<br>      string_not_equals = optional(list(object({<br>        key   = string<br>        value = string<br>      })), [])<br>      string_like = optional(list(object({<br>        key   = string<br>        value = string<br>      })), [])<br>      string_not_like = optional(list(object({<br>        key   = string<br>        value = string<br>      })), [])<br>    }))<br>    rules = map(object({<br>      name                     = optional(string)<br>      schedule                 = optional(string)<br>      start_window             = optional(number)<br>      completion_window        = optional(number)<br>      enable_continuous_backup = optional(bool)<br>      recovery_point_tags      = optional(map(string))<br>      lifecycle = optional(object({<br>        cold_storage_after = optional(number)<br>        delete_after       = optional(number)<br>      }))<br>      copy_action = optional(object({<br>        destination_vault_arn = optional(string)<br>        lifecycle = optional(object({<br>          cold_storage_after = optional(number)<br>          delete_after       = optional(number)<br>        }))<br>      }))<br>    }))<br>  }))</pre> | n/a | yes |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | n/a | `bool` | `true` | no |
| <a name="input_org_name"></a> [org\_name](#input\_org\_name) | n/a | `string` | n/a | yes |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | n/a | `string` | n/a | yes |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | n/a | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | `{}` | no |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | n/a | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->