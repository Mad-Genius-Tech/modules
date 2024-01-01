<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_context"></a> [context](#module\_context) | cloudposse/label/null | ~> 0.25.0 |
| <a name="module_rds"></a> [rds](#module\_rds) | terraform-aws-modules/rds/aws | ~> 6.1.1 |
| <a name="module_rds_sg"></a> [rds\_sg](#module\_rds\_sg) | terraform-aws-modules/security-group/aws | ~> 5.1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_db_instance_role_association.rds_lambda_role_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance_role_association) | resource |
| [aws_iam_policy.invoke_lambda_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.rds_invoke_lambda_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.rds_lambda_role_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_secretsmanager_secret.secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.secret_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [null_resource.disable_secret_rotation](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_secretsmanager_secret_version.secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_secret_manager"></a> [enable\_secret\_manager](#input\_enable\_secret\_manager) | n/a | `bool` | `true` | no |
| <a name="input_ingress_cidr_blocks"></a> [ingress\_cidr\_blocks](#input\_ingress\_cidr\_blocks) | n/a | `list(string)` | `[]` | no |
| <a name="input_ingress_security_group_id"></a> [ingress\_security\_group\_id](#input\_ingress\_security\_group\_id) | n/a | `string` | `""` | no |
| <a name="input_org_name"></a> [org\_name](#input\_org\_name) | n/a | `string` | n/a | yes |
| <a name="input_rds"></a> [rds](#input\_rds) | n/a | <pre>map(object({<br>    create                  = optional(bool)<br>    engine_version          = string<br>    instance_class          = string<br>    allocated_storage       = optional(number)<br>    max_allocated_storage   = optional(number)<br>    db_name                 = optional(string)<br>    username                = optional(string)<br>    port                    = optional(number)<br>    multi_az                = optional(bool)<br>    lambda_functions        = optional(list(string))<br>    apply_immediately       = optional(bool)<br>    secret_rotation_enabled = optional(bool)<br>    parameters = optional(list(object({<br>      name         = string<br>      value        = string<br>      apply_method = optional(string)<br>    })))<br><br>    options = optional(list(object({<br>      option_name = string<br>      option_settings = list(object({<br>        name  = string<br>        value = string<br>      }))<br>    })))<br>  }))</pre> | n/a | yes |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | n/a | `string` | n/a | yes |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | n/a | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | n/a | `list(any)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | `{}` | no |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | n/a | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_rds_info"></a> [rds\_info](#output\_rds\_info) | n/a |
<!-- END_TF_DOCS -->