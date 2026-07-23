## EventBridge Scheduler one-shot ECS tasks

Set an `ecs_services` entry to `type = "scheduled_task"` to create a task
definition without an ECS service and invoke it through
`aws_scheduler_schedule`. This path is deliberately different from the legacy
EventBridge rule/target integration: Scheduler uses
`scheduler.amazonaws.com`, applies the requested IANA timezone, and owns its
retry and dead-letter behavior.

Schedules are disabled by default. `scheduled.enabled = false` is the cutover
and rollback control; disabling a schedule does not delete its task definition,
roles, queue, logs, or prior immutable artifacts. The Scheduler target always
uses Fargate, a disabled flexible time window, private subnet defaults, and no
public IP unless a caller explicitly overrides the network fields.

### Stable identities and one-shot containers

Callers that need exact IAM identities can set:

- `task_definition_family`
- `tasks_iam_role_name` with `tasks_iam_role_use_name_prefix = false`
- `task_exec_iam_role_name` with
  `task_exec_iam_role_use_name_prefix = false`
- `scheduled.scheduler_role_name` with
  `scheduled.scheduler_role_use_name_prefix = false`

Omitting these fields preserves the existing generated-prefix behavior for
service callers. The Scheduler invocation policy permits `ecs:RunTask` only on
the resolved task definition and cluster. `iam:PassRole` contains only the
resolved task and execution roles and requires
`iam:PassedToService = ecs-tasks.amazonaws.com`.

An explicit `container_name` becomes the single container definition name and
the CloudWatch Logs suffix. For example, family
`mgb-dev-fabric-auth-migration-snapshot` and container
`migration-snapshot` produce
`/aws/ecs/mgb-dev-fabric-auth-migration-snapshot/migration-snapshot`.
`container_image` accepts an ECR digest such as `repository@sha256:...`.

For a non-service task, set `enable_port_mappings = false`,
`enable_health_check = false`, and `enable_default_ingress_rule = false`.
Supply only the required `security_group_egress_rules`. These are explicit
opt-ins so ordinary ECS service callers retain their existing port, HTTP health
check, VPC ingress, and broad egress defaults.

Container `secrets` are resolved through Secrets Manager data sources. A
scheduled task's execution role receives only those resolved secret ARNs (and
an exact repository-credential ARN only when that credential is actually used);
the service-caller's historical wildcard default is not reused as a scheduled
task shortcut.

### Retry, dead letter, and observability

`scheduled.maximum_retry_attempts` and
`scheduled.maximum_event_age_in_seconds` configure Scheduler delivery retries.
`scheduled.dead_letter_config` may set `create = true` for an encrypted module
queue or provide one existing `arn`, but not both. The Scheduler role receives
`sqs:SendMessage` only for that exact queue.

Per-task observability is absent by default. Setting
`scheduled.observability.enabled = true` creates three caller-scoped alarms:

| Failure boundary | Signal | Meaning |
|---|---|---|
| Scheduler launch/target | `AWS/Scheduler` `TargetErrorCount` for the task's dedicated schedule group | Scheduler could not deliver the ECS invocation |
| ECS task result | An exact task-definition/container EventBridge match and `AWS/Events` `TriggeredRules` | The invoked container stopped with a nonzero exit code |
| Successful-completion freshness | Caller-provided custom metric | No successful completion arrived within `freshness_window_seconds` |

The success signal is an application contract, not an inferred zero exit. The
task must publish one count to the configured `namespace`, `metric_name`, and
`dimensions` only after its complete success condition (including any artifact
publication) has passed. The freshness alarm uses the configured window,
divides it into `period_seconds` buckets, requires every bucket in the rolling
window to be breaching before alarming, and treats missing buckets as breaching.
One success count inside the current window therefore prevents the alarm until
that successful bucket ages out. This keeps launch delivery, process result,
and business completion distinct.

`ecs_scheduled_tasks` returns the exact schedule, task-definition, task-role,
execution-role, Scheduler-role, and dead-letter queue ARNs, plus the family,
role names, container/log-group identity, resolved execution secret ARNs, and
optional alarm ARNs.

### Network ownership boundary

This module creates no NAT gateway, interface endpoint, ECS service, ALB, EC2
runner, or mesh identity for a scheduled task. Environment IaC owns bootstrap
connectivity. When interface endpoints are absent, an already-running managed
NAT may carry encrypted ECR API/DKR, Secrets Manager, and CloudWatch Logs
bootstrap traffic. Private database traffic stays inside the VPC and S3
artifact traffic stays on the environment's gateway endpoint.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.56.0 |
| <a name="provider_external"></a> [external](#provider\_external) | 2.4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb"></a> [alb](#module\_alb) | terraform-aws-modules/alb/aws | ~> 9.1.0 |
| <a name="module_alb_internal"></a> [alb\_internal](#module\_alb\_internal) | terraform-aws-modules/alb/aws | ~> 9.1.0 |
| <a name="module_alb_internal_dedicated"></a> [alb\_internal\_dedicated](#module\_alb\_internal\_dedicated) | terraform-aws-modules/alb/aws | ~> 9.1.0 |
| <a name="module_context"></a> [context](#module\_context) | cloudposse/label/null | ~> 0.25.0 |
| <a name="module_ecs_cluster"></a> [ecs\_cluster](#module\_ecs\_cluster) | github.com/terraform-aws-modules/terraform-aws-ecs.git//modules/cluster | v5.5.0 |
| <a name="module_ecs_service"></a> [ecs\_service](#module\_ecs\_service) | github.com/terraform-aws-modules/terraform-aws-ecs.git//modules/service | v6.0.5 |
| <a name="module_ecs_service_multiples"></a> [ecs\_service\_multiples](#module\_ecs\_service\_multiples) | github.com/terraform-aws-modules/terraform-aws-ecs.git//modules/service | v6.0.5 |
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
| [aws_cloudwatch_event_rule.scheduled_task_nonzero_exit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.ecs_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.ecs_task_failure](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.ecs_task_stopped](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.ecs_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_metric_alarm.ecs_high_cpu_reservation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.ecs_high_mem_reservation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.ecs_low_cpu_reservation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.ecs_low_mem_reservation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.scheduled_task_freshness](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.scheduled_task_launch_failure](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.scheduled_task_nonzero_exit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_dynamodb_table.certmagic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_eip.eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_iam_role.scheduler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.scheduler_run_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_scheduler_schedule.ecs_scheduled_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/scheduler_schedule) | resource |
| [aws_scheduler_schedule_group.scheduled_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/scheduler_schedule_group) | resource |
| [aws_service_discovery_private_dns_namespace.service_discovery_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_private_dns_namespace) | resource |
| [aws_service_discovery_service.service_discovery](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service) | resource |
| [aws_sqs_queue.scheduled_task_dlq](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_acm_certificate.internal_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/acm_certificate) | data source |
| [aws_acm_certificate.non_wildcard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/acm_certificate) | data source |
| [aws_acm_certificate.wildcard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/acm_certificate) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_secretsmanager_secret.secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_security_group.cloudfront_vpc_origins](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |
| [external_external.current_image](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_container_insights"></a> [container\_insights](#input\_container\_insights) | n/a | `string` | `""` | no |
| <a name="input_create_certmagic_table"></a> [create\_certmagic\_table](#input\_create\_certmagic\_table) | n/a | `bool` | `false` | no |
| <a name="input_create_internal_alb"></a> [create\_internal\_alb](#input\_create\_internal\_alb) | n/a | `bool` | `true` | no |
| <a name="input_ecs_services"></a> [ecs\_services](#input\_ecs\_services) | n/a | <pre>map(object({<br>    type                           = optional(string, "service")<br>    container_image                = optional(string)<br>    require_repository_credentials = optional(bool)<br>    repository_credentials = optional(object({<br>      credentialsParameter = string<br>    }))<br>    create                                 = optional(bool)<br>    enable_service_discovery               = optional(bool)<br>    enable_execute_command                 = optional(bool, true)<br>    readonly_root_filesystem               = optional(bool, false)<br>    desired_count                          = optional(number)<br>    cpu_architecture                       = optional(string)<br>    fluentbit_cpu                          = optional(number)<br>    fluentbit_memory                       = optional(number)<br>    container_cpu                          = optional(number)<br>    container_memory                       = optional(number)<br>    memory_reservation                     = optional(number)<br>    container_port                         = optional(number)<br>    cloudwatch_log_group_retention_in_days = optional(number)<br>    availability_zone_rebalancing          = optional(string)<br>    enable_autoscaling                     = optional(bool)<br>    create_alb                             = optional(bool)<br>    external_alb                           = optional(bool)<br>    dedicated_internal_alb                 = optional(bool)<br>    internal_alb_hostnames                 = optional(list(string), [])<br>    create_nlb                             = optional(bool)<br>    create_eip                             = optional(bool)<br>    multiple_ports                         = optional(bool)<br>    health_check_port                      = optional(number)<br>    health_check_path                      = optional(string)<br>    healthy_threshold                      = optional(number)<br>    health_check_unhealthy_threshold       = optional(number)<br>    health_check_interval                  = optional(number)<br>    health_check_matcher                   = optional(string)<br>    wildcard_domain                        = optional(bool)<br>    domain_name                            = optional(string)<br>    task_exec_secret_arns                  = optional(list(string))<br>    task_definition_family                 = optional(string)<br>    task_exec_iam_role_name                = optional(string)<br>    task_exec_iam_role_use_name_prefix     = optional(bool, true)<br>    tasks_iam_role_name                    = optional(string)<br>    tasks_iam_role_use_name_prefix         = optional(bool, true)<br>    health_check_command                   = optional(list(string))<br>    enable_health_check                    = optional(bool, true)<br>    enable_port_mappings                   = optional(bool, true)<br>    enable_default_ingress_rule            = optional(bool, true)<br>    health_check_start_period              = optional(number)<br>    command                                = optional(list(string))<br>    entry_point                            = optional(list(string))<br>    health_check_grace_period_seconds      = optional(number)<br>    multiple_containers                    = optional(bool)<br>    subnet_ids                             = optional(list(string))<br>    user                                   = optional(string)<br>    deployment_minimum_healthy_percent     = optional(number)<br>    deployment_maximum_percent             = optional(number)<br>    capacity_provider_strategy = optional(map(object({<br>      base              = optional(number)<br>      capacity_provider = string<br>      weight            = optional(number)<br>    })))<br>    autoscaling_max_capacity = optional(number)<br>    autoscaling_scheduled_actions = optional(map(object({<br>      name         = optional(string)<br>      min_capacity = number<br>      max_capacity = number<br>      schedule     = string<br>      start_time   = optional(string)<br>      end_time     = optional(string)<br>      timezone     = optional(string)<br>    })))<br>    volume = optional(map(object({<br>      name      = string<br>      host_path = optional(string)<br>      efs_volume_configuration = optional(object({<br>        file_system_id          = string<br>        root_directory          = optional(string, "/")<br>        transit_encryption      = optional(string, "ENABLED")<br>        transit_encryption_port = optional(number, 2999)<br>        authorization_config = optional(object({<br>          access_point_id = optional(string)<br>          iam             = optional(string, "DISABLED")<br>        }))<br>      }))<br>    })))<br>    mount_points = optional(list(object({<br>      sourceVolume  = string<br>      containerPath = string<br>      readOnly      = optional(bool, false)<br>    })), [])<br>    environment = optional(list(object({<br>      name  = string<br>      value = string<br>    })))<br>    secrets = optional(list(object({<br>      name        = string<br>      secret_path = string<br>      secret_key  = string<br>    })))<br>    security_group_rules = optional(map(object({<br>      from_port   = number<br>      to_port     = number<br>      ip_protocol = optional(string, "tcp")<br>      description = optional(string)<br>      cidr_ipv4   = string<br>    })))<br>    security_group_egress_rules = optional(map(object({<br>      name                         = optional(string)<br>      cidr_ipv4                    = optional(string)<br>      cidr_ipv6                    = optional(string)<br>      description                  = optional(string)<br>      from_port                    = optional(string)<br>      ip_protocol                  = optional(string, "tcp")<br>      prefix_list_id               = optional(string)<br>      referenced_security_group_id = optional(string)<br>      tags                         = optional(map(string), {})<br>      to_port                      = optional(string)<br>    })))<br>    container_name = optional(string)<br>    container_definitions = optional(map(object({<br>      essential         = bool<br>      cpu               = number<br>      memory            = number<br>      memoryReservation = optional(number)<br>      image             = optional(string)<br>      repositoryCredentials = optional(object({<br>        credentialsParameter = string<br>      }))<br>      startTimeout = optional(number)<br>      stopTimeout  = optional(number)<br>      healthCheck = optional(object({<br>        command     = list(string)<br>        interval    = number<br>        timeout     = number<br>        retries     = number<br>        startPeriod = number<br>      }), null)<br>      environment = optional(list(object({<br>        name  = string<br>        value = string<br>      })))<br>      command = optional(list(string))<br>      portMappings = optional(list(object({<br>        containerPort = number<br>        hostPort      = number<br>        protocol      = string<br>      })))<br>      user = optional(string, "0")<br>      mount_points = optional(list(object({<br>        sourceVolume  = string<br>        containerPath = string<br>        readOnly      = optional(bool, false)<br>      })), [])<br>      readonlyRootFilesystem                 = optional(bool, false)<br>      enable_cloudwatch_logging              = optional(bool, true)<br>      create_cloudwatch_log_group            = optional(bool, true)<br>      cloudwatch_log_group_retention_in_days = optional(number)<br>      dependsOn = optional(list(object({<br>        containerName = string<br>        condition     = string<br>      })))<br>    })))<br>    tasks_iam_role_statements = optional(map(object({<br>      resources = list(string)<br>      actions   = list(string)<br>      conditions = optional(list(object({<br>        test     = string<br>        variable = string<br>        values   = list(string)<br>      })), [])<br>    })))<br>    scheduled = optional(object({<br>      enabled                        = optional(bool, false)<br>      schedule_expression            = optional(string)<br>      schedule_expression_timezone   = optional(string, "UTC")<br>      subnet_ids                     = optional(list(string))<br>      security_group_ids             = optional(list(string))<br>      assign_public_ip               = optional(bool, false)<br>      task_count                     = optional(number, 1)<br>      platform_version               = optional(string, "LATEST")<br>      maximum_retry_attempts         = optional(number, 0)<br>      maximum_event_age_in_seconds   = optional(number, 300)<br>      scheduler_role_name            = optional(string)<br>      scheduler_role_use_name_prefix = optional(bool, false)<br>      command                        = optional(list(string))<br>      cpu                            = optional(number)<br>      memory                         = optional(number)<br>      dead_letter_config = optional(object({<br>        arn                        = optional(string)<br>        create                     = optional(bool, false)<br>        name                       = optional(string)<br>        message_retention_seconds  = optional(number, 1209600)<br>        visibility_timeout_seconds = optional(number, 30)<br>      }))<br>      observability = optional(object({<br>        enabled       = optional(bool, false)<br>        alarm_actions = optional(list(string), [])<br>        ok_actions    = optional(list(string), [])<br>        success_signal = optional(object({<br>          namespace                = string<br>          metric_name              = string<br>          dimensions               = optional(map(string), {})<br>          statistic                = optional(string, "Sum")<br>          period_seconds           = optional(number, 3600)<br>          freshness_window_seconds = number<br>        }))<br>      }))<br>      # Source: exact `ecs_services` map key, or that service full `identifier` string (context-prefixed name in main.tf)<br>      reuse_task_definition_key = optional(string)<br>      # When the source is multiple_containers, which container in the task def to override (defaults: container_name, then first container_definitions key)<br>      reuse_container_name = optional(string)<br>    }))<br>  }))</pre> | n/a | yes |
| <a name="input_high_reservation_alert"></a> [high\_reservation\_alert](#input\_high\_reservation\_alert) | n/a | `bool` | `true` | no |
| <a name="input_ingress_cidr_blocks"></a> [ingress\_cidr\_blocks](#input\_ingress\_cidr\_blocks) | n/a | `list(string)` | n/a | yes |
| <a name="input_internal_alb_certificate_domains"></a> [internal\_alb\_certificate\_domains](#input\_internal\_alb\_certificate\_domains) | Ordered ACM certificate domains for shared internal ALB HTTPS; the first is the default and the rest are SNI certificates. | `list(string)` | `[]` | no |
| <a name="input_low_reservation_alert"></a> [low\_reservation\_alert](#input\_low\_reservation\_alert) | n/a | `bool` | `false` | no |
| <a name="input_org_name"></a> [org\_name](#input\_org\_name) | n/a | `string` | n/a | yes |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | n/a | `list(string)` | n/a | yes |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | n/a | `list(string)` | n/a | yes |
| <a name="input_service_discovery_dns_name"></a> [service\_discovery\_dns\_name](#input\_service\_discovery\_dns\_name) | n/a | `string` | `""` | no |
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
| <a name="output_alb_internal_dedicated_dns_name"></a> [alb\_internal\_dedicated\_dns\_name](#output\_alb\_internal\_dedicated\_dns\_name) | n/a |
| <a name="output_alb_internal_dns_name"></a> [alb\_internal\_dns\_name](#output\_alb\_internal\_dns\_name) | n/a |
| <a name="output_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#output\_ecs\_cluster\_arn) | n/a |
| <a name="output_ecs_cluster_id"></a> [ecs\_cluster\_id](#output\_ecs\_cluster\_id) | n/a |
| <a name="output_ecs_map"></a> [ecs\_map](#output\_ecs\_map) | n/a |
| <a name="output_ecs_scheduled_tasks"></a> [ecs\_scheduled\_tasks](#output\_ecs\_scheduled\_tasks) | n/a |
| <a name="output_ecs_services"></a> [ecs\_services](#output\_ecs\_services) | n/a |
| <a name="output_nlb_dns_name"></a> [nlb\_dns\_name](#output\_nlb\_dns\_name) | n/a |
<!-- END_TF_DOCS -->
