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

## Resources

| Name | Type |
|------|------|
| [aws_ivs_recording_configuration.recording_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ivs_recording_configuration) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ivs"></a> [ivs](#input\_ivs) | n/a | <pre>map(object({<br>    recording_configuration_s3_bucket_name = string<br>    thumbnail_configuration = optional(list(object({<br>      recording_mode          = optional(string)<br>      target_interval_seconds = optional(number)<br>    })))<br>    create = optional(bool)<br>  }))</pre> | n/a | yes |
| <a name="input_org_name"></a> [org\_name](#input\_org\_name) | n/a | `string` | n/a | yes |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | n/a | `string` | n/a | yes |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | n/a | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | `{}` | no |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ivs_configuration"></a> [ivs\_configuration](#output\_ivs\_configuration) | n/a |
<!-- END_TF_DOCS -->