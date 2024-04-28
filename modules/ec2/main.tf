
locals {

  default_settings = {
    instance_type               = "t3a.nano"
    ignore_ami_changes          = true
    associate_public_ip_address = false
    disable_api_stop            = false
    disable_api_termination     = false
    create_iam_instance_profile = true
    assign_eip                  = false
    iam_role_policies = {
      "AmazonEC2RoleforSSM"         = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
      "CloudWatchAgentServerPolicy" = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    }
    ingress_cidr_blocks        = []
    ingress_rules              = ["ssh-tcp"]
    ingress_with_cidr_blocks   = []
    key_name                   = ""
    subnet_id                  = ""
    cpu_credits                = "standard"
    aws_cloudwatch_auto_reboot = false
    use_ubuntu                 = false
    use_amazon_linux_2         = true
    cloudwatch_alarm_action    = ""
    monitoring                 = false
    enable_cloudwatch_alarm    = false
    alarms = {
      "statistic"               = "Average"
      "namespace"               = "AWS/EC2"
      "comparison_operator"     = "GreaterThanOrEqualToThreshold"
      "datapoints_to_alarm"     = 2
      "dimensions"              = {}
      "cloudwatch_alarm_action" = ""
    }
    policy              = {}
    root_volume_encrypt = false
    root_volume_type    = "gp2"
    root_volume_size    = 8
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
        enable_cloudwatch_alarm     = true
        cpu_credits                 = "unlimited"
        disable_api_stop            = true
        disable_api_termination     = true
        associate_public_ip_address = true
    })
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  ec2_map = {
    for k, v in var.ec2 : k => {
      "identifier"                  = "${module.context.id}-${k}"
      "create"                      = coalesce(lookup(v, "create", null), true)
      "instance_type"               = coalesce(lookup(v, "instance_type", null), local.merged_default_settings.instance_type)
      "ignore_ami_changes"          = coalesce(lookup(v, "ignore_ami_changes", null), local.merged_default_settings.ignore_ami_changes)
      "subnet_id"                   = try(coalesce(lookup(v, "subnet_id", null), local.merged_default_settings.subnet_id), local.merged_default_settings.subnet_id)
      "associate_public_ip_address" = coalesce(lookup(v, "associate_public_ip_address", null), local.merged_default_settings.associate_public_ip_address)
      "disable_api_stop"            = coalesce(lookup(v, "disable_api_stop", null), local.merged_default_settings.disable_api_stop)
      "disable_api_termination"     = coalesce(lookup(v, "disable_api_termination", null), local.merged_default_settings.disable_api_termination)
      "create_iam_instance_profile" = coalesce(lookup(v, "create_iam_instance_profile", null), local.merged_default_settings.create_iam_instance_profile)
      "iam_role_policies"           = merge(coalesce(lookup(v, "iam_role_policies", null), local.merged_default_settings.iam_role_policies), local.merged_default_settings.iam_role_policies)
      "key_name"                    = try(coalesce(lookup(v, "key_name", null), local.merged_default_settings.key_name), local.merged_default_settings.key_name)
      "ingress_cidr_blocks"         = distinct(compact(concat(coalesce(lookup(v, "ingress_cidr_blocks", null), local.merged_default_settings.ingress_cidr_blocks), local.merged_default_settings.ingress_cidr_blocks)))
      "ingress_rules"               = distinct(compact(concat(coalesce(lookup(v, "ingress_rules", null), local.merged_default_settings.ingress_rules), local.merged_default_settings.ingress_rules)))
      "assign_eip"                  = coalesce(lookup(v, "assign_eip", null), local.merged_default_settings.assign_eip)
      "cpu_credits"                 = coalesce(lookup(v, "cpu_credits", null), local.merged_default_settings.cpu_credits)
      "aws_cloudwatch_auto_reboot"  = coalesce(lookup(v, "aws_cloudwatch_auto_reboot", null), local.merged_default_settings.aws_cloudwatch_auto_reboot)
      "use_ubuntu"                  = coalesce(lookup(v, "use_ubuntu", null), local.merged_default_settings.use_ubuntu)
      "use_amazon_linux_2"          = coalesce(lookup(v, "use_amazon_linux_2", null), local.merged_default_settings.use_amazon_linux_2)
      "cloudwatch_alarm_action"     = try(coalesce(lookup(v, "cloudwatch_alarm_action", null), local.merged_default_settings.cloudwatch_alarm_action), local.merged_default_settings.cloudwatch_alarm_action)
      "monitoring"                  = coalesce(lookup(v, "monitoring", null), local.merged_default_settings.monitoring)
      "ingress_with_cidr_blocks"    = coalesce(lookup(v, "ingress_with_cidr_blocks", null), local.merged_default_settings.ingress_with_cidr_blocks)
      "policy"                      = coalesce(lookup(v, "policy", null), local.merged_default_settings.policy)
      "enable_cloudwatch_alarm"     = coalesce(lookup(v, "enable_cloudwatch_alarm", null), local.merged_default_settings.enable_cloudwatch_alarm)
      "alarms" = {
        for k1, v1 in coalesce(lookup(v, "alarms", null), {}) : k1 => {
          "identifier"              = "${module.context.id}-${k}-${k1}"
          "metric_name"             = v1.metric_name
          "threshold"               = v1.threshold
          "period"                  = v1.period
          "evaluation_periods"      = v1.evaluation_periods
          "datapoints_to_alarm"     = coalesce(lookup(v1, "datapoints_to_alarm", null), local.merged_default_settings.alarms.datapoints_to_alarm)
          "dimensions"              = coalesce(lookup(v1, "dimensions", null), local.merged_default_settings.alarms.dimensions)
          "comparison_operator"     = coalesce(lookup(v1, "comparison_operator", null), local.merged_default_settings.alarms.comparison_operator)
          "statistic"               = coalesce(lookup(v1, "statistic", null), local.merged_default_settings.alarms.statistic)
          "namespace"               = coalesce(lookup(v1, "namespace", null), local.merged_default_settings.alarms.namespace)
          "cloudwatch_alarm_action" = try(coalesce(lookup(v1, "cloudwatch_alarm_action", null), local.merged_default_settings.alarms.cloudwatch_alarm_action), local.merged_default_settings.alarms.cloudwatch_alarm_action)
        }
      }
      "root_volume_type"    = coalesce(lookup(v, "root_volume_type", null), local.merged_default_settings.root_volume_type)
      "root_volume_encrypt" = coalesce(lookup(v, "root_volume_encrypt", null), local.merged_default_settings.root_volume_encrypt)
      "root_volume_size"    = coalesce(lookup(v, "root_volume_size", null), local.merged_default_settings.root_volume_size)
    } if coalesce(lookup(v, "create", null), true)
  }
}

resource "random_shuffle" "public_subnet" {
  for_each = local.ec2_map
  input    = var.public_subnets
}

resource "random_shuffle" "private_subnet" {
  for_each = local.ec2_map
  input    = var.private_subnets
}

module "ec2" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "~> 5.5.0"
  for_each                    = local.ec2_map
  name                        = each.value.identifier
  instance_type               = each.value.instance_type
  ami                         = each.value.use_ubuntu ? data.aws_ami.ubuntu[each.key].id : (each.value.use_amazon_linux_2 ? data.aws_ami.amazon_linux_2[each.key].id : data.aws_ami.amazon_linux[each.key].id)
  ignore_ami_changes          = each.value.ignore_ami_changes
  subnet_id                   = each.value.subnet_id == "" ? (each.value.associate_public_ip_address ? random_shuffle.public_subnet[each.key].result[0] : random_shuffle.private_subnet[each.key].result[0]) : each.value.subnet_id
  associate_public_ip_address = each.value.associate_public_ip_address
  disable_api_stop            = each.value.disable_api_stop
  disable_api_termination     = each.value.disable_api_termination
  create_iam_instance_profile = each.value.create_iam_instance_profile
  iam_role_description        = "IAM role for EC2 ${each.value.identifier}"
  iam_role_policies = merge(
    {
      for k, v in local.ec2_policy : k => module.iam_policy[k].arn if startswith(k, "${each.key}|")
    },
    each.value.iam_role_policies
  )
  root_block_device = [
    {
      encrypted   = each.value.root_volume_encrypt
      volume_type = each.value.root_volume_type
      volume_size = each.value.root_volume_size
    },
  ]
  key_name               = each.value.key_name == "" ? (var.key_per_instance ? aws_key_pair.key_pair[each.key].key_name : one(values(aws_key_pair.key_pair)).key_name) : each.value.key_name
  vpc_security_group_ids = [module.sg[each.key].security_group_id]
  cpu_credits            = replace(each.value.instance_type, "/^t(2|3|3a){1}\\..*$/", "1") == "1" ? each.value.cpu_credits : null
  monitoring             = each.value.monitoring
  tags                   = local.tags
}

resource "aws_eip" "eip" {
  for_each = { for k, v in local.ec2_map : k => v if v.create && v.assign_eip }
  domain   = "vpc"
}

resource "aws_eip_association" "eip_assoc" {
  for_each      = { for k, v in local.ec2_map : k => v if v.create && v.assign_eip }
  instance_id   = module.ec2[each.key].id
  allocation_id = aws_eip.eip[each.key].id
}

resource "tls_private_key" "rsa" {
  for_each  = var.key_per_instance ? { for k, v in local.ec2_map : k => v.identifier } : { 1 = 1 }
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  for_each   = var.key_per_instance ? { for k, v in local.ec2_map : k => v.identifier } : { 1 = 1 }
  key_name   = var.key_per_instance ? "${each.value.identifier}-key" : "${module.context.id}-key"
  public_key = tls_private_key.rsa[each.key].public_key_openssh
  tags       = local.tags
}

resource "local_file" "private_key" {
  for_each        = var.output_private_key ? (var.key_per_instance ? { for k, v in local.ec2_map : k => v.identifier } : { 1 = 1 }) : {}
  content         = tls_private_key.rsa[each.key].private_key_pem
  filename        = var.key_per_instance ? "${var.terragrunt_directory}/${each.value.identifier}-key.pem" : "${var.terragrunt_directory}/${module.context.id}-key.pem"
  file_permission = "0600"
}

module "sg" {
  for_each                 = local.ec2_map
  source                   = "terraform-aws-modules/security-group/aws"
  version                  = "~> 5.1.0"
  name                     = each.value.identifier
  description              = "Security group for EC2 ${each.value.identifier}"
  vpc_id                   = var.vpc_id
  ingress_cidr_blocks      = length(each.value.ingress_cidr_blocks) > 0 ? each.value.ingress_cidr_blocks : []
  ingress_rules            = length(each.value.ingress_cidr_blocks) > 0 ? each.value.ingress_rules : []
  ingress_with_cidr_blocks = each.value.ingress_with_cidr_blocks
  egress_rules             = ["all-all"]
  tags                     = local.tags
}

locals {
  ec2_policy = merge([
    for k, v in local.ec2_map : {
      for k2, v2 in v.policy : "${k}|${k2}" => {
        name          = "${module.context.id}-${k}-${k2}"
        resources_arn = v2.resources_arn
        actions       = v2.actions
        conditions    = try(v2.conditions, null)
      }
    } if v.create && can(v.policy)
  ]...)
}

data "aws_iam_policy_document" "iam_policy" {
  for_each = local.ec2_policy
  statement {
    actions   = each.value.actions
    resources = each.value.resources_arn
    dynamic "condition" {
      for_each = can(each.value.conditions) && each.value.conditions != null ? each.value.conditions : {}
      content {
        test     = condition.value.test
        variable = condition.value.variable
        values   = condition.value.values
      }
    }
  }
}

module "iam_policy" {
  for_each      = local.ec2_policy
  source        = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version       = "~> 5.30.0"
  create_policy = true
  name          = each.value.name
  policy        = data.aws_iam_policy_document.iam_policy[each.key].json
  tags          = local.tags
}


data "aws_ami" "amazon_linux" {
  for_each    = { for k, v in local.ec2_map : k => v if v.create && !v.use_amazon_linux_2 }
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = var.architecture == "amd64" ? ["x86_64"] : ["arm64"]
  }
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-kernel-*"]
  }
}

data "aws_ami" "ubuntu" {
  for_each    = { for k, v in local.ec2_map : k => v if v.create && v.use_ubuntu }
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "architecture"
    values = var.architecture == "amd64" ? ["x86_64"] : ["arm64"]
  }
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-*-server*"]
  }
}


data "aws_ami" "amazon_linux_2" {
  for_each    = { for k, v in local.ec2_map : k => v if v.create && v.use_amazon_linux_2 }
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = var.architecture == "amd64" ? ["x86_64"] : ["arm64"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-hvm-*-gp2"]
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_cloudwatch_metric_alarm" "status_check" {
  for_each            = { for k, v in local.ec2_map : k => v if v.create && v.enable_cloudwatch_alarm }
  alarm_name          = "${each.value.identifier}-statuscheck"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 10
  metric_name         = "StatusCheckFailed_Instance"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 3
  dimensions = {
    InstanceId = module.ec2[each.key].id
  }
  alarm_actions = each.value.aws_cloudwatch_auto_reboot ? compact([
    "arn:aws:swf:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:action/actions/AWS_EC2.InstanceId.Reboot/1.0",
    var.sns_topic_arn,
    each.value.cloudwatch_alarm_action
    ]) : compact([
    var.sns_topic_arn,
    each.value.cloudwatch_alarm_action
  ])
  ok_actions = compact([
    var.sns_topic_arn,
    each.value.cloudwatch_alarm_action
  ])
  tags = local.tags
}



locals {
  alarms_map = merge([
    for k, v in local.ec2_map : {
      for k1, v1 in v.alarms : "${k}|${k1}" => v1
    } if v.create && v.enable_cloudwatch_alarm && length(v.alarms) > 0
  ]...)
}

resource "aws_cloudwatch_metric_alarm" "alarm" {
  for_each            = local.alarms_map
  alarm_name          = local.alarms_map[each.key].identifier
  alarm_description   = "This metric monitors EC2 ${local.ec2_map[split("|", each.key)[0]].identifier} ${local.alarms_map[each.key].metric_name}"
  metric_name         = local.alarms_map[each.key].metric_name
  comparison_operator = local.alarms_map[each.key].comparison_operator
  statistic           = local.alarms_map[each.key].statistic
  threshold           = local.alarms_map[each.key].threshold
  period              = local.alarms_map[each.key].period
  evaluation_periods  = local.alarms_map[each.key].evaluation_periods
  namespace           = local.alarms_map[each.key].namespace
  datapoints_to_alarm = local.alarms_map[each.key].datapoints_to_alarm
  dimensions = merge({
    InstanceId = module.ec2[split("|", each.key)[0]].id
  }, lookup(local.alarms_map[each.key], "dimensions", {}))
  alarm_actions = compact([
    var.sns_topic_arn,
    local.ec2_map[split("|", each.key)[0]].cloudwatch_alarm_action
  ])
  ok_actions = compact([
    var.sns_topic_arn,
    local.ec2_map[split("|", each.key)[0]].cloudwatch_alarm_action
  ])
  tags = local.tags
}
