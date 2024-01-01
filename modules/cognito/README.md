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
| [aws_cognito_identity_pool.identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_identity_pool) | resource |
| [aws_cognito_identity_pool_roles_attachment.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_identity_pool_roles_attachment) | resource |
| [aws_cognito_user_pool.pool](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool) | resource |
| [aws_cognito_user_pool_client.client](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client) | resource |
| [aws_iam_role.authenticated](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.unauthenticated](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.authenticated](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.unauthenticated](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cognito"></a> [cognito](#input\_cognito) | n/a | <pre>map(object({<br>    deletion_protection = optional(string)<br>    alias_attributes    = optional(list(string))<br>    username_configuration = optional(object({<br>      case_sensitive = optional(bool)<br>    }))<br>    auto_verified_attributes                      = optional(list(string))<br>    attributes_require_verification_before_update = optional(list(string))<br>    verification_message_template = optional(list(object({<br>      sms_message           = optional(string)<br>      email_message         = optional(string)<br>      email_subject         = optional(string)<br>      email_message_by_link = optional(string)<br>      email_subject_by_link = optional(string)<br>      default_email_option  = optional(string)<br>    })))<br>    recovery_mechanisms = optional(list(object({<br>      name     = optional(string)<br>      priority = optional(number)<br>    })))<br>    string_schemas = optional(list(object({<br>      attribute_data_type      = optional(string)<br>      developer_only_attribute = optional(bool)<br>      mutable                  = optional(bool)<br>      name                     = optional(string)<br>      required                 = optional(bool)<br>      string_attribute_constraints = optional(object({<br>        min_length = optional(number)<br>        max_length = optional(number)<br>      }))<br>    })))<br>    email_configuration = optional(list(object({<br>      from_email_address    = optional(string)<br>      source_arn            = optional(string)<br>      email_sending_account = optional(string)<br>    })))<br>    explicit_auth_flows                  = optional(list(string))<br>    prevent_user_existence_errors        = optional(string)<br>    enable_token_revocation              = optional(bool)<br>    access_token_validity                = optional(number)<br>    id_token_validity                    = optional(number)<br>    callback_urls                        = optional(list(string))<br>    supported_identity_providers         = optional(list(string))<br>    allowed_oauth_flows_user_pool_client = optional(bool)<br>    allowed_oauth_flows                  = optional(list(string))<br>    allowed_oauth_scopes                 = optional(list(string))<br>    read_attributes                      = optional(list(string))<br>    write_attributes                     = optional(list(string))<br>    token_validity_units = optional(list(object({<br>      access_token  = optional(string)<br>      id_token      = optional(string)<br>      refresh_token = optional(string)<br>    })))<br>  }))</pre> | n/a | yes |
| <a name="input_org_name"></a> [org\_name](#input\_org\_name) | n/a | `string` | n/a | yes |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | n/a | `string` | n/a | yes |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | n/a | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | `{}` | no |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | n/a | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->