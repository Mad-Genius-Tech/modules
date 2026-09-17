# CloudFront module

## Edge observability controls

Access logging and paid additional metrics are opt-in per distribution.
`enable_standard_logging_v2 = true` creates a private encrypted log bucket
with finite retention and a JSON delivery that excludes viewer IP, query
string, cookie, referer, user-agent, and forwarded-for fields. Override the
30-day retention with `logging_retention_days`; values outside 1–365 are
rejected.

The legacy `enable_logs` path remains for compatibility. Its cookie logging
defaults to disabled and must be explicitly enabled with
`logging_include_cookies = true`. New consumers should use standard logging v2
when they need privacy-filtered path evidence.

`enable_additional_metrics = true` creates the CloudFront monitoring
subscription that exposes cache-hit rate, origin latency, and status-specific
error metrics. Consumers must review cost and the exact plan before apply.

`enable_cloudwatch_alarms = true` creates separate `4xxErrorRate` and
`5xxErrorRate` alarms in `us-east-1`, where CloudFront publishes its global
metrics. Consumers must provide at least one `cloudwatch_alarm_actions` target
and explicitly review thresholds. AWS supports alarms from multiple Regions
targeting a common SNS topic, so an existing account-owned route can be reused;
verify its topic policy and delivery during runtime acceptance. Missing traffic
is non-breaching; successful recovery can route through
`cloudwatch_ok_actions`. Low-traffic sites can set
`cloudwatch_4xx_minimum_requests` to require that many requests in the same
period before the 4xx rate can breach. The default is `0`, which preserves the
direct error-rate alarm for existing consumers. This guard does not change the
5xx alarm.

Set `enable_cloudwatch_4xx_alarm = false` to retire only the 4xx alarm for a
static site whose rejected scanner requests do not warrant paging. It defaults
to `true`, preserving both alarms for existing callers that enable alarms.
The 5xx alarm keeps its resource address, thresholds and notification route;
access logging and additional metrics are independent of this setting.
The parent `enable_cloudwatch_alarms` switch still controls all alarms.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.65.0 |
| <a name="provider_aws.us-east-1"></a> [aws.us-east-1](#provider\_aws.us-east-1) | 6.65.0 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.9.1 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.4.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloudfront"></a> [cloudfront](#module\_cloudfront) | terraform-aws-modules/cloudfront/aws | ~> 5.0 |
| <a name="module_context"></a> [context](#module\_context) | cloudposse/label/null | ~> 0.25.0 |
| <a name="module_s3_bucket"></a> [s3\_bucket](#module\_s3\_bucket) | terraform-aws-modules/s3-bucket/aws | ~> 3.15.1 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_function.function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_function) | resource |
| [aws_cloudfront_key_group.cloudfront_key_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_key_group) | resource |
| [aws_cloudfront_monitoring_subscription.additional_metrics](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_monitoring_subscription) | resource |
| [aws_cloudfront_public_key.public_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_public_key) | resource |
| [aws_cloudwatch_log_delivery.standard_v2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_delivery) | resource |
| [aws_cloudwatch_log_delivery_destination.standard_v2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_delivery_destination) | resource |
| [aws_cloudwatch_log_delivery_source.standard_v2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_delivery_source) | resource |
| [aws_cloudwatch_metric_alarm.cloudfront_error_rate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_lambda_permission.cloudfront_lambda_url](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_s3_bucket_policy.bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_sns_topic.cloudfront_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.cloudfront_alarm_email](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [local_file.private_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.public_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [tls_private_key.private_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [aws_acm_certificate.non_wildcard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/acm_certificate) | data source |
| [aws_acm_certificate.wildcard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/acm_certificate) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_cloudfront_cache_policy.cache_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_cache_policy) | data source |
| [aws_cloudfront_cache_policy.customized_cache_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_cache_policy) | data source |
| [aws_cloudfront_cache_policy.default_cache_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_cache_policy) | data source |
| [aws_cloudfront_origin_request_policy.default_request_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_origin_request_policy) | data source |
| [aws_cloudfront_origin_request_policy.request_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_origin_request_policy) | data source |
| [aws_cloudfront_response_headers_policy.default_response_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_response_headers_policy) | data source |
| [aws_cloudfront_response_headers_policy.response_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_response_headers_policy) | data source |
| [aws_iam_policy_document.bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.standard_logging_v2_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_s3_bucket.s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_topic_email_subscriptions"></a> [alarm\_topic\_email\_subscriptions](#input\_alarm\_topic\_email\_subscriptions) | Email endpoints for a module-owned us-east-1 SNS topic that becomes the notification route for alarms with no explicit cloudwatch\_alarm\_actions. | `list(string)` | `[]` | no |
| <a name="input_cloudfront"></a> [cloudfront](#input\_cloudfront) | n/a | <pre>map(object({<br>    create                                 = optional(bool)<br>    enable_logs                            = optional(bool)<br>    enable_standard_logging_v2             = optional(bool)<br>    logging_include_cookies                = optional(bool)<br>    logging_retention_days                 = optional(number)<br>    enable_additional_metrics              = optional(bool)<br>    enable_cloudwatch_alarms               = optional(bool)<br>    enable_cloudwatch_4xx_alarm            = optional(bool)<br>    cloudwatch_alarm_actions               = optional(list(string))<br>    cloudwatch_ok_actions                  = optional(list(string))<br>    cloudwatch_alarm_period                = optional(number)<br>    cloudwatch_alarm_evaluation_periods    = optional(number)<br>    cloudwatch_alarm_datapoints_to_alarm   = optional(number)<br>    cloudwatch_4xx_minimum_requests        = optional(number)<br>    cloudwatch_4xx_error_rate_threshold    = optional(number)<br>    cloudwatch_5xx_error_rate_threshold    = optional(number)<br>    aliases                                = optional(list(string))<br>    enabled                                = optional(bool)<br>    price_class                            = optional(string)<br>    s3_bucket                              = optional(string)<br>    default_presigned_url                  = optional(bool)<br>    disable_presigned_url                  = optional(bool)<br>    use_acm_cert                           = optional(bool)<br>    wildcard_domain                        = optional(bool)<br>    domain_name                            = optional(string)<br>    domain_names                           = optional(list(string), [])<br>    default_allowed_http_methods           = optional(list(string))<br>    default_cache_behavior_allowed_methods = optional(list(string))<br>    origin_request_policy                  = optional(string)<br>    default_cache_policy                   = optional(string)<br>    default_origin_request_policy          = optional(string)<br>    default_response_headers_policy        = optional(string)<br>    default_target_origin_id               = optional(string)<br>    ordered_cache_enable_signed_url        = optional(bool)<br>    response_headers_policy                = optional(string)<br>    cache_policy                           = optional(string)<br>    compress                               = optional(bool)<br>    viewer_protocol_policy                 = optional(string)<br>    enable_upload_to_s3_origin             = optional(bool)<br>    default_root_object                    = optional(string)<br>    viewer_request_function_code           = optional(string)<br>    allow_list_bucket_access               = optional(bool)<br>    custom_error_response = optional(list(object({<br>      error_code            = number<br>      response_code         = number<br>      response_page_path    = string<br>      error_caching_min_ttl = optional(number)<br>    })))<br>    ordered_cache_behavior = optional(list(object({<br>      path_pattern                 = string<br>      target_origin_id             = string<br>      presigned_url                = optional(bool)<br>      viewer_protocol_policy       = optional(string)<br>      allowed_methods              = optional(list(string))<br>      cached_methods               = optional(list(string))<br>      compress                     = optional(bool)<br>      use_forwarded_values         = optional(bool)<br>      cache_policy_name            = optional(string)<br>      origin_request_policy_name   = optional(string)<br>      response_headers_policy_id   = optional(string)<br>      response_headers_policy_name = optional(string)<br>      trusted_key_groups           = optional(list(string))<br>      trusted_signers              = optional(list(string))<br>    })), [])<br>    origin_domain_name        = optional(string)<br>    origin_connection_timeout = optional(number)<br>    # Set to the Lambda function name when origin_domain_name is that<br>    # function's URL: creates a lambda-type OAC (sigv4-signed, AWS_IAM URLs)<br>    # and the invoke permission scoped to this distribution.<br>    lambda_url_origin_function_name = optional(string)<br>    vpc_origin = optional(object({<br>      arn                    = string<br>      name                   = optional(string)<br>      http_port              = optional(number)<br>      https_port             = optional(number)<br>      origin_protocol_policy = optional(string)<br>      origin_ssl_protocols   = optional(list(string))<br>    }))<br>    custom_origin_config = optional(object({<br>      http_port              = optional(number)<br>      https_port             = optional(number)<br>      origin_protocol_policy = optional(string)<br>      origin_ssl_protocols   = optional(list(string))<br>      origin_read_timeout    = optional(number)<br>    }))<br>  }))</pre> | n/a | yes |
| <a name="input_org_name"></a> [org\_name](#input\_org\_name) | n/a | `string` | n/a | yes |
| <a name="input_output_keyfile"></a> [output\_keyfile](#input\_output\_keyfile) | n/a | `bool` | `true` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | n/a | `string` | n/a | yes |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | n/a | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | `{}` | no |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | n/a | `string` | n/a | yes |
| <a name="input_terragrunt_directory"></a> [terragrunt\_directory](#input\_terragrunt\_directory) | n/a | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudfront_info"></a> [cloudfront\_info](#output\_cloudfront\_info) | n/a |
<!-- END_TF_DOCS -->
