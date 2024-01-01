<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_context"></a> [context](#module\_context) | cloudposse/label/null | ~> 0.25.0 |
| <a name="module_global_acm"></a> [global\_acm](#module\_global\_acm) | terraform-aws-modules/acm/aws | ~> 4.3.2 |
| <a name="module_regional_acm"></a> [regional\_acm](#module\_regional\_acm) | terraform-aws-modules/acm/aws | ~> 4.3.2 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_global_acm_domains"></a> [global\_acm\_domains](#input\_global\_acm\_domains) | n/a | `map(any)` | `{}` | no |
| <a name="input_org_name"></a> [org\_name](#input\_org\_name) | n/a | `string` | n/a | yes |
| <a name="input_regional_acm_domains"></a> [regional\_acm\_domains](#input\_regional\_acm\_domains) | n/a | `map(any)` | `{}` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | n/a | `string` | n/a | yes |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | n/a | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | `{}` | no |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_global_acm_certificate_arn"></a> [global\_acm\_certificate\_arn](#output\_global\_acm\_certificate\_arn) | n/a |
| <a name="output_global_validation_domains"></a> [global\_validation\_domains](#output\_global\_validation\_domains) | n/a |
| <a name="output_regional_acm_certificate_arn"></a> [regional\_acm\_certificate\_arn](#output\_regional\_acm\_certificate\_arn) | n/a |
| <a name="output_regional_validation_domains"></a> [regional\_validation\_domains](#output\_regional\_validation\_domains) | n/a |
<!-- END_TF_DOCS -->