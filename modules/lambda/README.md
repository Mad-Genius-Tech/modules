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
| <a name="module_lambda"></a> [lambda](#module\_lambda) | terraform-aws-modules/lambda/aws | ~> 6.0.0 |
| <a name="module_lambda_sg"></a> [lambda\_sg](#module\_lambda\_sg) | terraform-aws-modules/security-group/aws | ~> 5.1.0 |
| <a name="module_s3_bucket"></a> [s3\_bucket](#module\_s3\_bucket) | terraform-aws-modules/s3-bucket/aws | ~> 3.15.0 |
| <a name="module_stage_alias"></a> [stage\_alias](#module\_stage\_alias) | terraform-aws-modules/lambda/aws//modules/alias | ~> 6.0.0 |
| <a name="module_test_alias"></a> [test\_alias](#module\_test\_alias) | terraform-aws-modules/lambda/aws//modules/alias | ~> 6.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.cron](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.event_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.event_rule_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_lambda_event_source_mapping.map_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource |
| [aws_lambda_function_event_invoke_config.stage_invoke_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function_event_invoke_config) | resource |
| [aws_lambda_permission.cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.event_permission](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_s3_object.s3_object](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_dynamodb_table.table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/dynamodb_table) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_secretsmanager_secret.secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret_version.secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_lambda"></a> [lambda](#input\_lambda) | n/a | <pre>map(object({<br>    create                       = optional(bool)<br>    description                  = optional(string)<br>    handler                      = optional(string)<br>    runtime                      = optional(string)<br>    timeout                      = optional(number)<br>    memory_size                  = optional(number)<br>    ephemeral_storage_size       = optional(number)<br>    architectures                = optional(list(string))<br>    environment_variables        = optional(map(string))<br>    maximum_retry_attempts       = optional(number)<br>    maximum_event_age_in_seconds = optional(number)<br>    create_async_event_config    = optional(bool)<br>    policy_statements = optional(map(object({<br>      effect    = string<br>      actions   = list(string)<br>      resources = list(string)<br>    })))<br>    provisioned_concurrent_executions  = optional(number)<br>    cloudwatch_logs_retention_in_days  = optional(number)<br>    keep_warm                          = optional(bool)<br>    keep_warm_expression               = optional(string)<br>    policies                           = optional(list(string))<br>    db_instance_address                = optional(string)<br>    db_instance_arn                    = optional(string)<br>    db_instance_endpoint               = optional(string)<br>    db_instance_identifier             = optional(string)<br>    db_instance_master_user_secret_arn = optional(string)<br>    db_instance_name                   = optional(string)<br>    db_instance_port                   = optional(number)<br>    db_security_group_id               = optional(string)<br>    layers                             = optional(list(string))<br>    create_lambda_function_url         = optional(bool)<br>    cors                               = optional(object({<br>      allow_origins     = optional(list(string))<br>      allow_methods     = optional(list(string))<br>      allow_headers     = optional(list(string))<br>      expose_headers    = optional(list(string))<br>      max_age_seconds   = optional(number)<br>      allow_credentials = optional(bool)<br>    }))<br>    dynamodb_tables = optional(map(object({<br>      enabled                        = optional(bool)<br>      table_name                     = string<br>      batch_size                     = optional(number)<br>      starting_position              = optional(string)<br>      parallelization_factor         = optional(number)<br>      maximum_record_age_in_seconds  = optional(number)<br>      maximum_retry_attempts         = optional(number)<br>      bisect_batch_on_function_error = optional(bool)<br>    })))<br>    secret_vars = optional(map(object({<br>      secret_path = optional(string)<br>      property    = optional(string)<br>    })))<br>    cloudwatch_events = optional(map(object({<br>      rule_name           = optional(string)<br>      schedule_expression = optional(string)<br>    })))<br>  }))</pre> | `{}` | no |
| <a name="input_org_name"></a> [org\_name](#input\_org\_name) | n/a | `string` | n/a | yes |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | n/a | `string` | n/a | yes |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | n/a | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | n/a | `list(any)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | `{}` | no |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | n/a | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lambda_info"></a> [lambda\_info](#output\_lambda\_info) | n/a |
<!-- END_TF_DOCS -->