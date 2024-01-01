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