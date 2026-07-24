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
that CloudWatch can invoke from `us-east-1`, and explicitly review thresholds.
For SNS, use an `us-east-1` topic; do not point these global-region alarms at
the environment's workload-region topic. Missing traffic is non-breaching;
successful recovery can route through `cloudwatch_ok_actions`.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_aws.us-east-1"></a> [aws.us-east-1](#provider\_aws.us-east-1) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloudfront"></a> [cloudfront](#module\_cloudfront) | terraform-aws-modules/cloudfront/aws | ~> 3.2.1 |
| <a name="module_context"></a> [context](#module\_context) | cloudposse/label/null | ~> 0.25.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_function.function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_function) | resource |
| [aws_s3_bucket_policy.bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_acm_certificate.non_wildcard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/acm_certificate) | data source |
| [aws_acm_certificate.wildcard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/acm_certificate) | data source |
| [aws_cloudfront_cache_policy.cache_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_cache_policy) | data source |
| [aws_cloudfront_origin_request_policy.request_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_origin_request_policy) | data source |
| [aws_cloudfront_response_headers_policy.response_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_response_headers_policy) | data source |
| [aws_iam_policy_document.bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_s3_bucket.s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudfront"></a> [cloudfront](#input\_cloudfront) | n/a | <pre>map(object({<br>    create                                 = optional(bool)<br>    aliases                                = optional(list(string))<br>    enabled                                = optional(bool)<br>    price_class                            = optional(string)<br>    s3_bucket                              = optional(string)<br>    wildcard_domain                        = optional(bool)<br>    domain_name                            = string<br>    default_cache_behavior_allowed_methods = optional(list(string))<br>    origin_request_policy                  = optional(string)<br>    response_headers_policy                = optional(string)<br>    viewer_protocol_policy                 = optional(string)<br>    enable_upload_to_s3_origin             = optional(bool)<br>    default_root_object                    = optional(string)<br>    viewer_request_function_code           = optional(string)<br>    custom_error_response = optional(list(object({<br>      error_code            = number<br>      response_code         = number<br>      response_page_path    = string<br>      error_caching_min_ttl = optional(number)<br>    })))<br>    origin_domain_name = optional(string)<br>    custom_origin_config = optional(object({<br>      http_port              = optional(number)<br>      https_port             = optional(number)<br>      origin_protocol_policy = optional(string)<br>      origin_ssl_protocols   = optional(list(string))<br>    }))<br>  }))</pre> | n/a | yes |
| <a name="input_org_name"></a> [org\_name](#input\_org\_name) | n/a | `string` | n/a | yes |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | n/a | `string` | n/a | yes |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | n/a | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | `{}` | no |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudfront_info"></a> [cloudfront\_info](#output\_cloudfront\_info) | n/a |
<!-- END_TF_DOCS -->
