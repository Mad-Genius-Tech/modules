# SNS notifications

The topic delivers to its email subscriptions and, when a Slack webhook is
configured, the Python standard-library adapter in `slack/`. The adapter accepts
SNS text, including CloudWatch alarm JSON and ECS event JSON, and raises
sanitized errors when Slack rejects delivery. It uses no Lambda SDK layer.

Recognized CloudWatch alarms also render a plain-text Slack card with the alarm
name, state, reason, description, region and change time. The original SNS text
remains the diagnostic fallback. Task-failure OK cards say that a quiet failure
window does not verify service recovery. Unknown notifications keep their
existing plain-text delivery; card text cannot interpret Slack mentions.

The topic policy permits Budgets, CloudWatch and Cost Anomaly Detection to
publish. Cost Anomaly Detection is restricted to the account that owns the
topic, including topics with email delivery and no Slack forwarder.

The forwarder retains logs for 30 days. Its error alarm publishes to the same
topic; configure a confirmed email subscription as an independent route. The
alarm has no recovery action, which prevents its own failed notification from
starting an ALARM/OK notification loop.

Use `sns_email_message_body_filter_policy` to narrow email delivery with a JSON
message-body policy. For example, `jsonencode({ AlarmName = ["mgb-dev-sns-slack-errors"] })`
retains email for the forwarder's own failure alarm while ordinary notifications
use Slack. The default is null, which preserves unfiltered email delivery.
The filter does not change the Lambda subscription or its notification path.

Run `python3 tests/test_slack.py` and `terraform test -test-directory=tftests`
from this directory. Terraform tests mock AWS and do not send notifications.
Runtime regression tests can also run in the AWS Lambda Python 3.10 image with
networking disabled. A live Slack probe requires separate authorization.

Consumers retain the existing `module.sns` path and nested resource names. Before
applying a consumer pin, verify the saved plan preserves the Lambda, role, topic,
log group and subscriptions. Module tests do not establish live-state safety.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.67.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_context"></a> [context](#module\_context) | cloudposse/label/null | ~> 0.25.0 |
| <a name="module_sns"></a> [sns](#module\_sns) | ./slack | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_metric_alarm.slack_delivery_errors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_sns_topic.topic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.aws_budget](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_sns_topic_subscription.subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create"></a> [create](#input\_create) | n/a | `bool` | `true` | no |
| <a name="input_org_name"></a> [org\_name](#input\_org\_name) | n/a | `string` | n/a | yes |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | n/a | `string` | n/a | yes |
| <a name="input_sns_email_message_body_filter_policy"></a> [sns\_email\_message\_body\_filter\_policy](#input\_sns\_email\_message\_body\_filter\_policy) | Optional SNS message-body filter policy as a JSON object for email subscriptions. Null preserves unfiltered email delivery. | `string` | `null` | no |
| <a name="input_sns_email_subscriptions"></a> [sns\_email\_subscriptions](#input\_sns\_email\_subscriptions) | n/a | `list(string)` | `[]` | no |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | n/a | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | `{}` | no |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | n/a | `string` | n/a | yes |
| <a name="input_webhook_url"></a> [webhook\_url](#input\_webhook\_url) | n/a | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_sns_topic_arn"></a> [sns\_topic\_arn](#output\_sns\_topic\_arn) | n/a |
| <a name="output_sns_topic_name"></a> [sns\_topic\_name](#output\_sns\_topic\_name) | n/a |
<!-- END_TF_DOCS -->
