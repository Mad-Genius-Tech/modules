<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_external"></a> [external](#provider\_external) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb"></a> [alb](#module\_alb) | terraform-aws-modules/alb/aws | ~> 9.1.0 |
| <a name="module_alb_internal"></a> [alb\_internal](#module\_alb\_internal) | terraform-aws-modules/alb/aws | ~> 9.1.0 |
| <a name="module_context"></a> [context](#module\_context) | cloudposse/label/null | ~> 0.25.0 |
| <a name="module_ecs_cluster"></a> [ecs\_cluster](#module\_ecs\_cluster) | github.com/terraform-aws-modules/terraform-aws-ecs.git//modules/cluster | v5.5.0 |
| <a name="module_ecs_service"></a> [ecs\_service](#module\_ecs\_service) | github.com/terraform-aws-modules/terraform-aws-ecs.git//modules/service | v5.5.0 |
| <a name="module_log_bucket"></a> [log\_bucket](#module\_log\_bucket) | terraform-aws-modules/s3-bucket/aws | ~> 3.15.1 |
| <a name="module_nlb"></a> [nlb](#module\_nlb) | terraform-aws-modules/alb/aws | ~> 9.1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_dashboard.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |
| [aws_cloudwatch_event_rule.ecs_deployment_failure](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.ecs_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.ecs_task_failure](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.ecs_task_stopped](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.ecs_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.ecs_task_failure](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.ecs_task_stopped](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.ecs_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_metric_alarm.ecs_high_cpu_reservation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.ecs_high_mem_reservation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.ecs_low_cpu_reservation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.ecs_low_mem_reservation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_dynamodb_table.certmagic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_eip.eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_acm_certificate.non_wildcard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/acm_certificate) | data source |
| [aws_acm_certificate.wildcard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/acm_certificate) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_secretsmanager_secret.secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [external_external.current_image](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ecs_services"></a> [ecs\_services](#input\_ecs\_services) | n/a | <pre>map(object({<br>    container_image = optional(string)<br>    repository_credentials = optional(object({<br>      credentialsParameter = string<br>    }))<br>    create                                 = optional(bool)<br>    desired_count                          = optional(number)<br>    fluentbit_cpu                          = optional(number)<br>    fluentbit_memory                       = optional(number)<br>    container_cpu                          = optional(number)<br>    container_memory                       = optional(number)<br>    memory_reservation                     = optional(number)<br>    container_port                         = optional(number)<br>    cloudwatch_log_group_retention_in_days = optional(number)<br>    enable_autoscaling                     = optional(bool)<br>    create_alb                             = optional(bool)<br>    external_alb                           = optional(bool)<br>    create_nlb                             = optional(bool)<br>    create_eip                             = optional(bool)<br>    multiple_ports                         = optional(bool)<br>    health_check_port                      = optional(number)<br>    health_check_path                      = optional(string)<br>    wildcard_domain                        = optional(bool)<br>    domain_name                            = optional(string)<br>    task_exec_secret_arns                  = optional(list(string))<br>    health_check_start_period              = optional(number)<br>    environment = optional(list(object({<br>      name  = string<br>      value = string<br>    })))<br>    secrets = optional(list(object({<br>      name        = string<br>      secret_path = string<br>      secret_key  = string<br>    })))<br>    security_group_rules = optional(map(object({<br>      type        = string<br>      from_port   = number<br>      to_port     = number<br>      protocol    = string<br>      description = optional(string)<br>      cidr_blocks = list(string)<br>    })))<br>    tasks_iam_role_statements = optional(map(object({<br>      resources = list(string)<br>      actions   = list(string)<br>      conditions = optional(list(object({<br>        test     = string<br>        variable = string<br>        values   = list(string)<br>      })), [])<br>    })))<br>  }))</pre> | n/a | yes |
| <a name="input_high_reservation_alert"></a> [high\_reservation\_alert](#input\_high\_reservation\_alert) | n/a | `bool` | `true` | no |
| <a name="input_ingress_cidr_blocks"></a> [ingress\_cidr\_blocks](#input\_ingress\_cidr\_blocks) | n/a | `list(string)` | n/a | yes |
| <a name="input_low_reservation_alert"></a> [low\_reservation\_alert](#input\_low\_reservation\_alert) | n/a | `bool` | `false` | no |
| <a name="input_org_name"></a> [org\_name](#input\_org\_name) | n/a | `string` | n/a | yes |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | n/a | `list(string)` | n/a | yes |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | n/a | `list(string)` | n/a | yes |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | n/a | `string` | n/a | yes |
| <a name="input_sns_topic_cloudwatch_alarm_arn"></a> [sns\_topic\_cloudwatch\_alarm\_arn](#input\_sns\_topic\_cloudwatch\_alarm\_arn) | n/a | `string` | `""` | no |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | n/a | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | `{}` | no |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | n/a | `string` | n/a | yes |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | n/a | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_dns_name"></a> [alb\_dns\_name](#output\_alb\_dns\_name) | n/a |
| <a name="output_alb_internal_dns_name"></a> [alb\_internal\_dns\_name](#output\_alb\_internal\_dns\_name) | n/a |
| <a name="output_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#output\_ecs\_cluster\_arn) | n/a |
| <a name="output_ecs_cluster_id"></a> [ecs\_cluster\_id](#output\_ecs\_cluster\_id) | n/a |
| <a name="output_ecs_services"></a> [ecs\_services](#output\_ecs\_services) | n/a |
| <a name="output_nlb_dns_name"></a> [nlb\_dns\_name](#output\_nlb\_dns\_name) | n/a |
<!-- END_TF_DOCS -->