<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aurora_postgresql_v2"></a> [aurora\_postgresql\_v2](#module\_aurora\_postgresql\_v2) | terraform-aws-modules/rds-aurora/aws | ~> 8.3.1 |
| <a name="module_context"></a> [context](#module\_context) | cloudposse/label/null | ~> 0.25.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_metric_alarm.alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_iam_policy.invoke_lambda_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.rds_invoke_lambda_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.rds_lambda_role_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_rds_cluster_role_association.rds_lambda_role_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_role_association) | resource |
| [aws_secretsmanager_secret.secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.secret_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_rds_engine_version.aurora](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/rds_engine_version) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aurora"></a> [aurora](#input\_aurora) | n/a | <pre>map(object({<br>    create                       = optional(bool)<br>    version                      = optional(string)<br>    min_capacity                 = optional(number)<br>    max_capacity                 = optional(number)<br>    master_username              = optional(string)<br>    database_name                = optional(string)<br>    skip_final_snapshot          = optional(bool)<br>    backup_retention_period      = optional(number)<br>    performance_insights_enabled = optional(bool)<br>    monitoring_interval          = optional(number)<br>    instances                    = optional(map(any))<br>    instances_count              = optional(number)<br>    enable_cloudwatch_alarm      = optional(bool)<br>    alarms = optional(map(object({<br>      metric_name             = string<br>      comparison_operator     = optional(string)<br>      dimensions              = optional(map(string), {})<br>      threshold               = number<br>      evaluation_periods      = number<br>      period                  = number<br>      statistic               = optional(string)<br>      namespace               = optional(string)<br>      cloudwatch_alarm_action = optional(string)<br>    })))<br>  }))</pre> | `{}` | no |
| <a name="input_ingress_cidr_blocks"></a> [ingress\_cidr\_blocks](#input\_ingress\_cidr\_blocks) | n/a | `list(string)` | `[]` | no |
| <a name="input_org_name"></a> [org\_name](#input\_org\_name) | n/a | `string` | n/a | yes |
| <a name="input_security_group_rules"></a> [security\_group\_rules](#input\_security\_group\_rules) | n/a | `map(any)` | `{}` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | n/a | `string` | n/a | yes |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | n/a | `string` | `""` | no |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | n/a | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | n/a | `list(any)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | `{}` | no |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | n/a | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aurora_info"></a> [aurora\_info](#output\_aurora\_info) | n/a |
<!-- END_TF_DOCS -->