<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_awsutils"></a> [awsutils](#requirement\_awsutils) | >= 0.18.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_local"></a> [local](#provider\_local) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_context"></a> [context](#module\_context) | cloudposse/label/null | ~> 0.25.0 |
| <a name="module_ec2"></a> [ec2](#module\_ec2) | terraform-aws-modules/ec2-instance/aws | ~> 5.5.0 |
| <a name="module_iam_policy"></a> [iam\_policy](#module\_iam\_policy) | terraform-aws-modules/iam/aws//modules/iam-policy | ~> 5.30.0 |
| <a name="module_sg"></a> [sg](#module\_sg) | terraform-aws-modules/security-group/aws | ~> 5.1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_metric_alarm.alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.status_check](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_eip.eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eip_association.eip_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip_association) | resource |
| [aws_key_pair.key_pair](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [local_file.private_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [random_shuffle.private_subnet](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/shuffle) | resource |
| [random_shuffle.public_subnet](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/shuffle) | resource |
| [tls_private_key.rsa](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [aws_ami.amazon_linux](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.amazon_linux_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_architecture"></a> [architecture](#input\_architecture) | n/a | `string` | `"amd64"` | no |
| <a name="input_ec2"></a> [ec2](#input\_ec2) | n/a | <pre>map(object({<br>    create                      = optional(bool)<br>    ignore_ami_changes          = optional(bool)<br>    instance_type               = optional(string)<br>    subnet_id                   = optional(string)<br>    associate_public_ip_address = optional(bool)<br>    disable_api_stop            = optional(bool)<br>    disable_api_termination     = optional(bool)<br>    create_iam_instance_profile = optional(bool)<br>    iam_role_policies           = optional(map(string))<br>    policy = optional(map(object({<br>      resources_arn = list(string)<br>      actions       = list(string)<br>      conditions = optional(map(object({<br>        test     = string<br>        variable = string<br>        values   = list(string)<br>      })))<br>    })))<br>    key_name            = optional(string)<br>    ingress_cidr_blocks = optional(list(string))<br>    ingress_rules       = optional(list(string))<br>    ingress_with_cidr_blocks = optional(list(object({<br>      from_port   = number<br>      to_port     = number<br>      protocol    = string<br>      description = optional(string)<br>      cidr_blocks = string<br>    })))<br>    assign_eip                 = optional(bool)<br>    cpu_credits                = optional(string)<br>    aws_cloudwatch_auto_reboot = optional(bool)<br>    use_ubuntu                 = optional(bool)<br>    use_amazon_linux_2         = optional(bool)<br>    cloudwatch_alarm_action    = optional(string)<br>    enable_cloudwatch_alarm    = optional(bool)<br>    monitoring                 = optional(bool)<br>    root_volume_size           = optional(number)<br>    alarms = optional(map(object({<br>      metric_name             = string<br>      comparison_operator     = optional(string)<br>      dimensions              = optional(map(string), {})<br>      threshold               = number<br>      evaluation_periods      = number<br>      period                  = number<br>      statistic               = optional(string)<br>      namespace               = optional(string)<br>      cloudwatch_alarm_action = optional(string)<br>    })))<br>  }))</pre> | n/a | yes |
| <a name="input_key_per_instance"></a> [key\_per\_instance](#input\_key\_per\_instance) | n/a | `bool` | `false` | no |
| <a name="input_org_name"></a> [org\_name](#input\_org\_name) | n/a | `string` | n/a | yes |
| <a name="input_output_private_key"></a> [output\_private\_key](#input\_output\_private\_key) | n/a | `bool` | `false` | no |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | n/a | `list(string)` | `[]` | no |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | n/a | `list(string)` | `[]` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | n/a | `string` | n/a | yes |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | n/a | `string` | `""` | no |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | n/a | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | `{}` | no |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | n/a | `string` | n/a | yes |
| <a name="input_terragrunt_directory"></a> [terragrunt\_directory](#input\_terragrunt\_directory) | n/a | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ec2_info"></a> [ec2\_info](#output\_ec2\_info) | n/a |
<!-- END_TF_DOCS -->