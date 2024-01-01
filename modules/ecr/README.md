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
| <a name="module_ecr_repository"></a> [ecr\_repository](#module\_ecr\_repository) | terraform-aws-modules/ecr/aws | ~> 1.6.0 |

## Resources

| Name | Type |
|------|------|
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ecr_repositories"></a> [ecr\_repositories](#input\_ecr\_repositories) | n/a | <pre>map(object({<br>    create                          = optional(bool)<br>    repository_force_delete         = optional(bool)<br>    repository_type                 = optional(string)<br>    repository_image_tag_mutability = optional(string)<br>    repository_encryption_type      = optional(string)<br>    repository_image_scan_on_push   = optional(bool)<br>    attach_repository_policy        = optional(bool)<br>    enable_lambda_download          = optional(bool)<br>    repository_policy               = optional(string)<br>    create_repository_policy        = optional(bool)<br>    create_lifecycle_policy         = optional(bool)<br>    repository_lifecycle_policy     = optional(string)<br>  }))</pre> | `{}` | no |
| <a name="input_org_name"></a> [org\_name](#input\_org\_name) | n/a | `string` | n/a | yes |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | n/a | `string` | n/a | yes |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | n/a | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | `{}` | no |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ecr_repository"></a> [ecr\_repository](#output\_ecr\_repository) | n/a |
<!-- END_TF_DOCS -->