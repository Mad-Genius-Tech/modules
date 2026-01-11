locals {

  instance_type = {
    "kafka.t3.small" = {
      cpu    = 2
      memory = 2
    },
    "kafka.m7g.large" = {
      cpu    = 2
      memory = 8
    },
    "kafka.m7g.xlarge" = {
      cpu    = 4
      memory = 16
    },
    "kafka.m7g.2xlarge" = {
      cpu    = 8
      memory = 32
    },
    "kafka.m7g.4xlarge" = {
      cpu    = 16
      memory = 64
    },
    "kafka.m7g.8xlarge" = {
      cpu    = 32
      memory = 128
    },
  }

  configuration_server_properties = {
    "auto.create.topics.enable"           = true
    "delete.topic.enable"                 = true
    "allow.everyone.if.no.acl.found"      = false
    "replica.selector.class"              = "org.apache.kafka.common.replica.RackAwareReplicaSelector"
    "log.message.timestamp.before.max.ms" = 9223372036854775807
    "log.message.timestamp.after.max.ms"  = 9223372036854775807
  }

  default_settings = {
    kafka_version                   = "3.8.x"
    number_of_broker_nodes          = 3
    enhanced_monitoring             = "DEFAULT"
    broker_node_instance_type       = "kafka.t3.small"
    storage_mode                    = "LOCAL" # Tiered not supported on t3.small
    broker_node_storage_volume_size = 25
    jmx_exporter_enabled            = false
    node_exporter_enabled           = false
    cloudwatch_logs_enabled         = false
    s3_logs_enabled                 = false
    create_scram_secret_association = true
    msk_secrets                     = { "admin" = { accesses = [] } }
    enable_cloudwatch_alarm         = false
    alarms = {
      "statistic"               = "Average"
      "namespace"               = "AWS/Kafka"
      "comparison_operator"     = "GreaterThanOrEqualToThreshold"
      "dimensions"              = {}
      "cloudwatch_alarm_action" = ""
      "cluster_level_alarm"     = true
    }
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
        broker_node_instance_type       = "kafka.m7g.large"
        storage_mode                    = "TIERED"
        broker_node_storage_volume_size = 50
    })
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  msk_map = {
    for k, v in var.msk : k => {
      "create"                          = coalesce(lookup(v, "create", null), true)
      "identifier"                      = strcontains(module.context.id, k) ? module.context.id : "${module.context.id}-${k}"
      "kafka_version"                   = try(coalesce(lookup(v, "kafka_version", null), local.merged_default_settings.kafka_version), local.merged_default_settings.kafka_version)
      "number_of_broker_nodes"          = try(coalesce(lookup(v, "number_of_broker_nodes", null), local.merged_default_settings.number_of_broker_nodes), local.merged_default_settings.number_of_broker_nodes)
      "enhanced_monitoring"             = try(coalesce(lookup(v, "enhanced_monitoring", null), local.merged_default_settings.enhanced_monitoring), local.merged_default_settings.enhanced_monitoring)
      "broker_node_instance_type"       = try(coalesce(lookup(v, "broker_node_instance_type", null), local.merged_default_settings.broker_node_instance_type), local.merged_default_settings.broker_node_instance_type)
      "broker_node_storage_volume_size" = try(coalesce(lookup(v, "broker_node_storage_volume_size", null), local.merged_default_settings.broker_node_storage_volume_size), local.merged_default_settings.broker_node_storage_volume_size)
      "storage_mode"                    = try(coalesce(lookup(v, "storage_mode", null), local.merged_default_settings.storage_mode), local.merged_default_settings.storage_mode)
      "jmx_exporter_enabled"            = try(coalesce(lookup(v, "jmx_exporter_enabled", null), local.merged_default_settings.jmx_exporter_enabled), local.merged_default_settings.jmx_exporter_enabled)
      "node_exporter_enabled"           = try(coalesce(lookup(v, "node_exporter_enabled", null), local.merged_default_settings.node_exporter_enabled), local.merged_default_settings.node_exporter_enabled)
      "cloudwatch_logs_enabled"         = try(coalesce(lookup(v, "cloudwatch_logs_enabled", null), local.merged_default_settings.cloudwatch_logs_enabled), local.merged_default_settings.cloudwatch_logs_enabled)
      "s3_logs_enabled"                 = try(coalesce(lookup(v, "s3_logs_enabled", null), local.merged_default_settings.s3_logs_enabled), local.merged_default_settings.s3_logs_enabled)
      "create_scram_secret_association" = try(coalesce(lookup(v, "create_scram_secret_association", null), local.merged_default_settings.create_scram_secret_association), local.merged_default_settings.create_scram_secret_association)
      "configuration_server_properties" = merge(local.configuration_server_properties, {
        # Speeding up log recovery after unclean shutdown
        # https://docs.aws.amazon.com/msk/latest/developerguide/bestpractices.html#bestpractices-monitor-disk-space#:~:text=Speeding%20up%20log%20recovery%20after,unclean%20shutdown
        "num.recovery.threads.per.data.dir" = lookup(local.instance_type, try(coalesce(lookup(v, "broker_node_instance_type", null), local.merged_default_settings.broker_node_instance_type), local.merged_default_settings.broker_node_instance_type)).cpu
      })
      "msk_secrets"             = try(coalesce(lookup(v, "msk_secrets", null), local.merged_default_settings.msk_secrets), local.merged_default_settings.msk_secrets)
      "enable_cloudwatch_alarm" = coalesce(lookup(v, "enable_cloudwatch_alarm", null), local.merged_default_settings.enable_cloudwatch_alarm)
      "alarms" = {
        for k1, v1 in coalesce(lookup(v, "alarms", null), {}) : k1 => {
          "identifier"              = "${module.context.id}-${k}-${k1}"
          "metric_name"             = v1.metric_name
          "threshold"               = v1.threshold
          "period"                  = v1.period
          "evaluation_periods"      = v1.evaluation_periods
          "dimensions"              = coalesce(lookup(v1, "dimensions", null), local.merged_default_settings.alarms.dimensions)
          "comparison_operator"     = coalesce(lookup(v1, "comparison_operator", null), local.merged_default_settings.alarms.comparison_operator)
          "statistic"               = coalesce(lookup(v1, "statistic", null), local.merged_default_settings.alarms.statistic)
          "namespace"               = coalesce(lookup(v1, "namespace", null), local.merged_default_settings.alarms.namespace)
          "cloudwatch_alarm_action" = try(coalesce(lookup(v1, "cloudwatch_alarm_action", null), local.merged_default_settings.alarms.cloudwatch_alarm_action), local.merged_default_settings.alarms.cloudwatch_alarm_action)
          "cluster_level_alarm"     = coalesce(lookup(v1, "cluster_level_alarm", null), local.merged_default_settings.alarms.cluster_level_alarm)
        }
      }
    } if coalesce(lookup(v, "create", null), true)
  }
}

module "msk_kafka_cluster" {
  for_each                   = local.msk_map
  source                     = "terraform-aws-modules/msk-kafka-cluster/aws"
  version                    = "~> 2.13.0"
  create                     = each.value.create
  name                       = each.value.identifier
  kafka_version              = each.value.kafka_version
  enhanced_monitoring        = each.value.enhanced_monitoring
  number_of_broker_nodes     = each.value.number_of_broker_nodes
  broker_node_instance_type  = each.value.broker_node_instance_type
  broker_node_client_subnets = var.private_subnet_ids
  broker_node_connectivity_info = {
    public_access = {
      type = "DISABLED"
    }
  }

  broker_node_security_groups = [aws_security_group.broker_security_group[each.key].id]
  broker_node_storage_info = {
    ebs_storage_info = {
      volume_size = each.value.broker_node_storage_volume_size
      provisioned_throughput = {
        enabled = false
      }
    }
  }
  storage_mode               = each.value.broker_node_instance_type == "kafka.t3.small" ? "LOCAL" : each.value.storage_mode
  enable_storage_autoscaling = false
  # Storage is scaled up to x1.5 the initial provisioned storage
  scaling_max_capacity = each.value.broker_node_storage_volume_size * each.value.number_of_broker_nodes * 1.5
  # % Kafka broker storage utilization at which scaling is initiated
  scaling_target_value = 60

  encryption_in_transit_client_broker = "TLS"
  encryption_in_transit_in_cluster    = true

  configuration_name              = each.value.identifier
  configuration_description       = "Configuration of ${each.value.identifier}"
  configuration_server_properties = local.configuration_server_properties

  jmx_exporter_enabled    = each.value.jmx_exporter_enabled
  node_exporter_enabled   = each.value.node_exporter_enabled
  cloudwatch_logs_enabled = each.value.cloudwatch_logs_enabled
  s3_logs_enabled         = each.value.s3_logs_enabled
  s3_logs_bucket          = each.value.s3_logs_enabled ? module.s3_logs_bucket[each.key].bucket : null
  s3_logs_prefix          = each.value.s3_logs_enabled ? each.value.identifier : null

  client_authentication = {
    sasl = {
      scram = true
      iam   = true
    }
  }

  create_scram_secret_association          = each.value.create_scram_secret_association
  scram_secret_association_secret_arn_list = each.value.create_scram_secret_association ? [for x in aws_secretsmanager_secret.secrets : x.arn] : null

  tags = local.tags
}


locals {
  alarms_map = merge([
    for k, v in local.msk_map : {
      for k1, v1 in v.alarms : "${k}|${k1}" => v1
    } if v.create && v.enable_cloudwatch_alarm && length(v.alarms) > 0
  ]...)
}

resource "aws_cloudwatch_metric_alarm" "alarm_cluster" {
  for_each            = { for k, v in local.alarms_map : k => v if v.cluster_level_alarm }
  alarm_name          = local.alarms_map[each.key].identifier
  alarm_description   = "This metric monitors MSK ${local.msk_map[split("|", each.key)[0]].identifier} ${local.alarms_map[each.key].metric_name}"
  metric_name         = local.alarms_map[each.key].metric_name
  comparison_operator = local.alarms_map[each.key].comparison_operator
  statistic           = local.alarms_map[each.key].statistic
  threshold           = local.alarms_map[each.key].threshold
  period              = local.alarms_map[each.key].period
  evaluation_periods  = local.alarms_map[each.key].evaluation_periods
  namespace           = local.alarms_map[each.key].namespace
  dimensions = merge({
    ClusterName = module.msk_kafka_cluster[split("|", each.key)[0]].cluster_name
  }, lookup(local.alarms_map[each.key], "dimensions", {}))
  alarm_actions = compact([
    var.sns_topic_arn,
    lookup(local.msk_map[split("|", each.key)[0]], "cloudwatch_alarm_action", "")
  ])
  ok_actions = compact([
    var.sns_topic_arn,
    lookup(local.msk_map[split("|", each.key)[0]], "cloudwatch_alarm_action", "")
  ])
  tags = local.tags
}

locals {
  node_numbers   = ["1", "2", "3"]
  alarm_keys_set = toset(keys({ for k, v in local.alarms_map : k => v if v.cluster_level_alarm == false }))
  node_idx_set   = toset(local.node_numbers)
  product        = setproduct(local.alarm_keys_set, local.node_idx_set)
  node_alarms = {
    for pair in local.product :
    "${pair[0]}|${pair[1]}" => {
      key   = pair[0]
      value = local.alarms_map[pair[0]]
      idx   = tonumber(pair[1])
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "alarm_node" {
  for_each            = local.node_alarms
  alarm_name          = "${local.node_alarms[each.key].value.identifier}-broker-${local.node_alarms[each.key].idx}"
  alarm_description   = "This metric monitors MSK ${local.msk_map[split("|", each.key)[0]].identifier} broker ${local.node_alarms[each.key].idx} ${local.node_alarms[each.key].value.metric_name}"
  metric_name         = local.node_alarms[each.key].value.metric_name
  comparison_operator = local.node_alarms[each.key].value.comparison_operator
  statistic           = local.node_alarms[each.key].value.statistic
  threshold           = local.node_alarms[each.key].value.threshold
  period              = local.node_alarms[each.key].value.period
  evaluation_periods  = local.node_alarms[each.key].value.evaluation_periods
  namespace           = local.node_alarms[each.key].value.namespace
  dimensions = merge({
    "Cluster Name" = module.msk_kafka_cluster[split("|", each.key)[0]].cluster_name
    "Broker ID"    = local.node_alarms[each.key].idx
  }, lookup(local.node_alarms[each.key].value, "dimensions", {}))
  alarm_actions = compact([
    var.sns_topic_arn,
    lookup(local.msk_map[split("|", each.key)[0]], "cloudwatch_alarm_action", "")
  ])
  ok_actions = compact([
    var.sns_topic_arn,
    lookup(local.msk_map[split("|", each.key)[0]], "cloudwatch_alarm_action", "")
  ])
  tags = local.tags
}

data "aws_subnet" "private_subnet" {
  for_each = toset(var.private_subnet_ids)
  id       = each.value
}

locals {
  private_subnet_cidrs = [for subnet in data.aws_subnet.private_subnet : subnet.cidr_block]
}


resource "aws_security_group" "broker_security_group" {
  for_each = {
    for k, v in local.msk_map : k => v if v.create
  }
  name_prefix = each.value.identifier

  description = "Security group for ${each.value.identifier} MSK brokers"

  vpc_id = var.vpc_id

  # To communicate with brokers in plaintext use port 9092
  # To communicate with brokers with TLS encryption port 9094
  # To communicate with brokers with SASL/SCRAM use port 9096
  # To communicate with brokers with IAM access use port 9098
  ingress {
    description = "Broker access"
    from_port   = 9092
    to_port     = 9098
    protocol    = "tcp"
    cidr_blocks = local.private_subnet_cidrs

  }

  # JMX Exporter - 11001
  # Node Exporter - 11002
  ingress {
    description = "JMX and Node Exporter"
    from_port   = 11001
    to_port     = 11002
    protocol    = "tcp"
    cidr_blocks = local.private_subnet_cidrs
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = -1
    self      = true
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = -1
    self      = true
  }

  lifecycle {
    create_before_destroy = true
  }
}