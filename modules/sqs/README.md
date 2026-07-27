# SQS

Creates standard or FIFO SQS queues with an optional dead-letter queue. New queues retain messages for 14 days, use 20-second long polling, and use SQS-managed encryption unless a customer-managed KMS key is supplied.

Each entry in `sqs` produces one primary queue. `queue_arns`, `queue_urls`, `dlq_arns`, and `dlq_urls` are keyed by the same entry name so a caller can grant only the send or receive permissions it needs.

## Minimal primary-plus-DLQ example

```hcl
module "queues" {
  source = "git::https://github.com/Mad-Genius-Tech/modules.git//modules/sqs?ref=<immutable-commit>"

  org_name     = "example"
  stage_name   = "dev"
  service_name = "events"
  team_name    = "platform"

  sqs = {
    delivery = {
      visibility_timeout_seconds = 120
      max_receive_count          = 5
      create_queue_policy        = true

      queue_policy_statements = {
        consumer = {
          effect  = "Allow"
          actions = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
          principals = [{
            type        = "AWS"
            identifiers = ["arn:aws:iam::123456789012:role/example-consumer"]
          }]
        }
      }
    }
  }
}
```

`queue_policy_statements` and `dlq_queue_policy_statements` attach resource policies only when their corresponding `create_*_queue_policy` flag is true. IAM identity policies for applications remain the caller's responsibility.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_context"></a> [context](#module\_context) | cloudposse/label/null | ~> 0.25.0 |
| <a name="module_dlq_alarm"></a> [dlq\_alarm](#module\_dlq\_alarm) | terraform-aws-modules/cloudwatch/aws//modules/metric-alarm | ~> 5.4.0 |
| <a name="module_sqs"></a> [sqs](#module\_sqs) | terraform-aws-modules/sqs/aws | ~> 4.1.1 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_org_name"></a> [org\_name](#input\_org\_name) | n/a | `string` | n/a | yes |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | n/a | `string` | n/a | yes |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | n/a | `string` | `""` | no |
| <a name="input_sqs"></a> [sqs](#input\_sqs) | n/a | <pre>map(object({<br>    create                                = optional(bool)<br>    fifo_queue                            = optional(bool)<br>    use_name_prefix                       = optional(bool)<br>    create_queue_policy                   = optional(bool)<br>    visibility_timeout_seconds            = optional(number)<br>    message_retention_seconds             = optional(number)<br>    receive_wait_time_seconds             = optional(number)<br>    max_receive_count                     = optional(number)<br>    redrive_policy                        = optional(map(any))<br>    sqs_managed_sse_enabled               = optional(bool)<br>    kms_master_key_id                     = optional(string)<br>    kms_data_key_reuse_period_seconds     = optional(number)<br>    queue_policy_statements               = optional(any)<br>    source_queue_policy_documents         = optional(list(string))<br>    override_queue_policy_documents       = optional(list(string))<br>    create_dlq                            = optional(bool)<br>    create_dlq_queue_policy               = optional(bool)<br>    create_dlq_redrive_allow_policy       = optional(bool)<br>    dlq_message_retention_seconds         = optional(number)<br>    dlq_receive_wait_time_seconds         = optional(number)<br>    dlq_visibility_timeout_seconds        = optional(number)<br>    dlq_sqs_managed_sse_enabled           = optional(bool)<br>    dlq_kms_master_key_id                 = optional(string)<br>    dlq_kms_data_key_reuse_period_seconds = optional(number)<br>    dlq_queue_policy_statements           = optional(any)<br>    source_dlq_queue_policy_documents     = optional(list(string))<br>    override_dlq_queue_policy_documents   = optional(list(string))<br>    dlq_redrive_allow_policy              = optional(any)<br>  }))</pre> | `{}` | no |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | n/a | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | `{}` | no |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dlq_arns"></a> [dlq\_arns](#output\_dlq\_arns) | ARNs for dead-letter queues, keyed by the caller's sqs map key. Values are null when create\_dlq is false. |
| <a name="output_dlq_urls"></a> [dlq\_urls](#output\_dlq\_urls) | URLs for dead-letter queues, keyed by the caller's sqs map key. Values are null when create\_dlq is false. |
| <a name="output_queue_arns"></a> [queue\_arns](#output\_queue\_arns) | ARNs for primary queues, keyed by the caller's sqs map key. |
| <a name="output_queue_urls"></a> [queue\_urls](#output\_queue\_urls) | URLs for primary queues, keyed by the caller's sqs map key. |
<!-- END_TF_DOCS -->
