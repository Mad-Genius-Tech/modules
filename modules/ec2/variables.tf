variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type    = list(string)
  default = []
}

variable "private_subnets" {
  type    = list(string)
  default = []
}

variable "ec2" {
  type = map(object({
    create                           = optional(bool)
    ignore_ami_changes               = optional(bool)
    architecture                     = optional(string, "amd64")
    instance_type                    = optional(string)
    subnet_id                        = optional(string)
    associate_public_ip_address      = optional(bool)
    disable_api_stop                 = optional(bool)
    disable_api_termination          = optional(bool)
    enable_alb                       = optional(bool)
    wildcard_domain                  = optional(bool)
    domain_name                      = optional(string)
    listening_port                   = optional(number)
    health_check_path                = optional(string)
    health_check_interval            = optional(number)
    health_check_timeout             = optional(number)
    health_check_healthy_threshold   = optional(number)
    health_check_unhealthy_threshold = optional(number)
    alb_ingress_cidrs_ipv4           = optional(list(string))
    create_iam_instance_profile      = optional(bool)
    iam_role_policies                = optional(map(string))
    policy = optional(map(object({
      resources_arn = list(string)
      actions       = list(string)
      conditions = optional(map(object({
        test     = string
        variable = string
        values   = list(string)
      })))
    })))
    key_name            = optional(string)
    ingress_cidr_blocks = optional(list(string))
    ingress_rules       = optional(list(string))
    ingress_with_cidr_blocks = optional(list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      description = optional(string)
      cidr_blocks = string
    })))
    ingress_with_ipv6_cidr_blocks = optional(list(object({
      from_port        = number
      to_port          = number
      protocol         = string
      description      = optional(string)
      ipv6_cidr_blocks = string
    })))
    assign_eip                 = optional(bool)
    cpu_credits                = optional(string)
    aws_cloudwatch_auto_reboot = optional(bool)
    use_ubuntu                 = optional(bool)
    use_amazon_linux_2         = optional(bool)
    cloudwatch_alarm_action    = optional(string)
    enable_cloudwatch_alarm    = optional(bool)
    monitoring                 = optional(bool)
    root_volume_size           = optional(number)
    root_volume_type           = optional(string)
    ami                        = optional(string)
    alarms = optional(map(object({
      enabled                 = optional(bool, true)
      metric_name             = string
      comparison_operator     = optional(string)
      dimensions              = optional(map(string), {})
      threshold               = number
      evaluation_periods      = number
      period                  = number
      statistic               = optional(string)
      namespace               = optional(string)
      cloudwatch_alarm_action = optional(string)
      treat_missing_data      = optional(string)
    })))
    tags = optional(map(string))
  }))
}

variable "terragrunt_directory" {
  type    = string
  default = ""
}

variable "key_per_instance" {
  type    = bool
  default = false
}

variable "output_private_key" {
  type    = bool
  default = false
}

variable "sns_topic_arn" {
  type    = string
  default = ""
}