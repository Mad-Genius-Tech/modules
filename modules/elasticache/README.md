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
| <a name="module_redis_sg"></a> [redis\_sg](#module\_redis\_sg) | terraform-aws-modules/security-group/aws | ~> 5.1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_elasticache_parameter_group.parameter_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_parameter_group) | resource |
| [aws_elasticache_replication_group.redis](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_replication_group) | resource |
| [aws_elasticache_subnet_group.subnet_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_subnet_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ingress_cidr_blocks"></a> [ingress\_cidr\_blocks](#input\_ingress\_cidr\_blocks) | n/a | `list(string)` | `[]` | no |
| <a name="input_ingress_security_group_id"></a> [ingress\_security\_group\_id](#input\_ingress\_security\_group\_id) | n/a | `string` | `""` | no |
| <a name="input_org_name"></a> [org\_name](#input\_org\_name) | n/a | `string` | n/a | yes |
| <a name="input_redis"></a> [redis](#input\_redis) | n/a | <pre>map(object({<br>    create                     = optional(bool)<br>    node_type                  = optional(string)<br>    engine_version             = optional(string)<br>    transit_encryption_enabled = optional(bool)<br>    auth_token                 = optional(string)<br>    at_rest_encryption_enabled = optional(bool)<br>    multi_az_enabled           = optional(bool)<br>    automatic_failover_enabled = optional(bool)<br>    snapshot_retention_limit   = optional(number)<br>    num_cache_clusters         = optional(number)<br>    num_node_groups            = optional(number)<br>    replicas_per_node_group    = optional(number)<br>    auto_minor_version_upgrade = optional(bool)<br>    kms_key_id                 = optional(string)<br>    parameters = optional(map(object({<br>      name  = string<br>      value = string<br>    })))<br>  }))</pre> | `{}` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | n/a | `string` | n/a | yes |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | n/a | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | n/a | `list(any)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | `{}` | no |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | n/a | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_redis_info"></a> [redis\_info](#output\_redis\_info) | n/a |
<!-- END_TF_DOCS -->