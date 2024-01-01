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
| <a name="module_context"></a> [context](#module\_context) | cloudposse/label/null | ~> 0.25.0 |
| <a name="module_opensearch_sg"></a> [opensearch\_sg](#module\_opensearch\_sg) | terraform-aws-modules/security-group/aws | ~> 5.1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.opensearch_application_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.opensearch_audit_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.opensearch_index_slow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.opensearch_search_slow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_service_linked_role.es](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [aws_opensearch_domain.opensearch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/opensearch_domain) | resource |
| [aws_opensearch_domain_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/opensearch_domain_policy) | resource |
| [aws_secretsmanager_secret.secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.secret_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_acm_certificate.non_wildcard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/acm_certificate) | data source |
| [aws_acm_certificate.wildcard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/acm_certificate) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_service_name_for_linked_role"></a> [aws\_service\_name\_for\_linked\_role](#input\_aws\_service\_name\_for\_linked\_role) | AWS service name for linked role. | `string` | `"opensearchservice.amazonaws.com"` | no |
| <a name="input_create_linked_role"></a> [create\_linked\_role](#input\_create\_linked\_role) | n/a | `bool` | `false` | no |
| <a name="input_enable_secret_manager"></a> [enable\_secret\_manager](#input\_enable\_secret\_manager) | n/a | `bool` | `true` | no |
| <a name="input_ingress_cidr_blocks"></a> [ingress\_cidr\_blocks](#input\_ingress\_cidr\_blocks) | n/a | `list(string)` | `[]` | no |
| <a name="input_ingress_security_group_id"></a> [ingress\_security\_group\_id](#input\_ingress\_security\_group\_id) | n/a | `string` | `""` | no |
| <a name="input_opensearch"></a> [opensearch](#input\_opensearch) | n/a | <pre>map(object({<br>    create                         = optional(bool)<br>    engine_version                 = optional(string)<br>    instance_type                  = optional(string)<br>    instance_count                 = optional(number)<br>    zone_awareness_enabled         = optional(bool)<br>    dedicated_master_enabled       = optional(bool)<br>    dedicated_master_type          = optional(string)<br>    dedicated_master_count         = optional(number)<br>    warm_enabled                   = optional(bool)<br>    warm_count                     = optional(number)<br>    warm_type                      = optional(string)<br>    encrypt_at_rest_enabled        = optional(bool)<br>    node_to_node_encryption        = optional(bool)<br>    security_options_enabled       = optional(bool)<br>    anonymous_auth_enabled         = optional(bool)<br>    internal_user_database_enabled = optional(bool)<br>    master_user_name               = optional(string)<br>    ebs_enabled                    = optional(bool)<br>    volume_type                    = optional(string)<br>    volume_size                    = optional(number)<br>    iops                           = optional(number)<br>    throughput                     = optional(number)<br>    wildcard_domain                = optional(bool)<br>    custom_endpoint                = optional(string)<br>    enforce_https                  = optional(bool)<br>    tls_security_policy            = optional(string)<br>    audit_logs_enabled             = optional(bool)<br>    search_logs_enabled            = optional(bool)<br>    index_logs_enabled             = optional(bool)<br>    application_logs_enabled       = optional(bool)<br>    retention_in_days              = optional(number)<br>    iam_role_arns                  = optional(list(string))<br>    availability_zone_count        = optional(number)<br>  }))</pre> | `{}` | no |
| <a name="input_org_name"></a> [org\_name](#input\_org\_name) | n/a | `string` | n/a | yes |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | n/a | `string` | n/a | yes |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | n/a | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | n/a | `list(any)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | `{}` | no |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | n/a | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_opensearch_info"></a> [opensearch\_info](#output\_opensearch\_info) | n/a |
<!-- END_TF_DOCS -->