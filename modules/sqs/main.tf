
locals {
  default_settings = {
    fifo_queue                            = false
    use_name_prefix                       = false
    create_queue_policy                   = false
    create_dlq                            = true
    create_dlq_queue_policy               = false
    create_dlq_redrive_allow_policy       = true
    message_retention_seconds             = 1209600
    dlq_message_retention_seconds         = 1209600
    receive_wait_time_seconds             = 20
    dlq_receive_wait_time_seconds         = 20
    visibility_timeout_seconds            = 30
    dlq_visibility_timeout_seconds        = 30
    max_receive_count                     = 5
    redrive_policy                        = {}
    sqs_managed_sse_enabled               = true
    dlq_sqs_managed_sse_enabled           = true
    kms_master_key_id                     = null
    dlq_kms_master_key_id                 = null
    kms_data_key_reuse_period_seconds     = null
    dlq_kms_data_key_reuse_period_seconds = null
    queue_policy_statements               = {}
    dlq_queue_policy_statements           = {}
    source_queue_policy_documents         = []
    override_queue_policy_documents       = []
    source_dlq_queue_policy_documents     = []
    override_dlq_queue_policy_documents   = []
    dlq_redrive_allow_policy              = {}
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {

      }
    )
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  sqs_map = {
    for k, v in var.sqs : k => {
      identifier                            = "${module.context.id}-${k}"
      create                                = coalesce(v.create, true)
      fifo_queue                            = coalesce(v.fifo_queue, local.merged_default_settings.fifo_queue)
      use_name_prefix                       = coalesce(v.use_name_prefix, local.merged_default_settings.use_name_prefix)
      create_queue_policy                   = coalesce(v.create_queue_policy, local.merged_default_settings.create_queue_policy)
      create_dlq                            = coalesce(v.create_dlq, local.merged_default_settings.create_dlq)
      create_dlq_queue_policy               = coalesce(v.create_dlq_queue_policy, local.merged_default_settings.create_dlq_queue_policy)
      create_dlq_redrive_allow_policy       = coalesce(v.create_dlq_redrive_allow_policy, local.merged_default_settings.create_dlq_redrive_allow_policy)
      message_retention_seconds             = coalesce(v.message_retention_seconds, local.merged_default_settings.message_retention_seconds)
      dlq_message_retention_seconds         = coalesce(v.dlq_message_retention_seconds, local.merged_default_settings.dlq_message_retention_seconds)
      receive_wait_time_seconds             = coalesce(v.receive_wait_time_seconds, local.merged_default_settings.receive_wait_time_seconds)
      dlq_receive_wait_time_seconds         = coalesce(v.dlq_receive_wait_time_seconds, local.merged_default_settings.dlq_receive_wait_time_seconds)
      visibility_timeout_seconds            = coalesce(v.visibility_timeout_seconds, local.merged_default_settings.visibility_timeout_seconds)
      dlq_visibility_timeout_seconds        = coalesce(v.dlq_visibility_timeout_seconds, local.merged_default_settings.dlq_visibility_timeout_seconds)
      sqs_managed_sse_enabled               = coalesce(v.sqs_managed_sse_enabled, local.merged_default_settings.sqs_managed_sse_enabled)
      dlq_sqs_managed_sse_enabled           = coalesce(v.dlq_sqs_managed_sse_enabled, local.merged_default_settings.dlq_sqs_managed_sse_enabled)
      kms_master_key_id                     = try(coalesce(v.kms_master_key_id, local.merged_default_settings.kms_master_key_id), null)
      dlq_kms_master_key_id                 = try(coalesce(v.dlq_kms_master_key_id, local.merged_default_settings.dlq_kms_master_key_id), null)
      kms_data_key_reuse_period_seconds     = try(coalesce(v.kms_data_key_reuse_period_seconds, local.merged_default_settings.kms_data_key_reuse_period_seconds), null)
      dlq_kms_data_key_reuse_period_seconds = try(coalesce(v.dlq_kms_data_key_reuse_period_seconds, local.merged_default_settings.dlq_kms_data_key_reuse_period_seconds), null)
      queue_policy_statements               = coalesce(v.queue_policy_statements, local.merged_default_settings.queue_policy_statements)
      dlq_queue_policy_statements           = coalesce(v.dlq_queue_policy_statements, local.merged_default_settings.dlq_queue_policy_statements)
      source_queue_policy_documents         = coalesce(v.source_queue_policy_documents, local.merged_default_settings.source_queue_policy_documents)
      override_queue_policy_documents       = coalesce(v.override_queue_policy_documents, local.merged_default_settings.override_queue_policy_documents)
      source_dlq_queue_policy_documents     = coalesce(v.source_dlq_queue_policy_documents, local.merged_default_settings.source_dlq_queue_policy_documents)
      override_dlq_queue_policy_documents   = coalesce(v.override_dlq_queue_policy_documents, local.merged_default_settings.override_dlq_queue_policy_documents)
      dlq_redrive_allow_policy              = coalesce(v.dlq_redrive_allow_policy, local.merged_default_settings.dlq_redrive_allow_policy)
      redrive_policy = coalesce(v.create_dlq, local.merged_default_settings.create_dlq) ? merge(
        coalesce(v.redrive_policy, local.merged_default_settings.redrive_policy),
        {
          maxReceiveCount = coalesce(
            v.max_receive_count,
            try(v.redrive_policy.maxReceiveCount, null),
            local.merged_default_settings.max_receive_count,
          )
        },
      ) : coalesce(v.redrive_policy, local.merged_default_settings.redrive_policy)
    } if coalesce(lookup(v, "create", null), true)
  }
}

module "sqs" {
  source                                = "terraform-aws-modules/sqs/aws"
  version                               = "~> 4.1.1"
  for_each                              = local.sqs_map
  name                                  = each.value.identifier
  fifo_queue                            = each.value.fifo_queue
  use_name_prefix                       = each.value.use_name_prefix
  visibility_timeout_seconds            = each.value.visibility_timeout_seconds
  message_retention_seconds             = each.value.message_retention_seconds
  receive_wait_time_seconds             = each.value.receive_wait_time_seconds
  sqs_managed_sse_enabled               = each.value.sqs_managed_sse_enabled
  kms_master_key_id                     = each.value.kms_master_key_id
  kms_data_key_reuse_period_seconds     = each.value.kms_data_key_reuse_period_seconds
  create_queue_policy                   = each.value.create_queue_policy
  queue_policy_statements               = each.value.queue_policy_statements
  source_queue_policy_documents         = each.value.source_queue_policy_documents
  override_queue_policy_documents       = each.value.override_queue_policy_documents
  create_dlq                            = each.value.create_dlq
  create_dlq_queue_policy               = each.value.create_dlq_queue_policy
  create_dlq_redrive_allow_policy       = each.value.create_dlq_redrive_allow_policy
  dlq_message_retention_seconds         = each.value.dlq_message_retention_seconds
  dlq_receive_wait_time_seconds         = each.value.dlq_receive_wait_time_seconds
  dlq_visibility_timeout_seconds        = each.value.dlq_visibility_timeout_seconds
  dlq_sqs_managed_sse_enabled           = each.value.dlq_sqs_managed_sse_enabled
  dlq_kms_master_key_id                 = each.value.dlq_kms_master_key_id
  dlq_kms_data_key_reuse_period_seconds = each.value.dlq_kms_data_key_reuse_period_seconds
  dlq_queue_policy_statements           = each.value.dlq_queue_policy_statements
  source_dlq_queue_policy_documents     = each.value.source_dlq_queue_policy_documents
  override_dlq_queue_policy_documents   = each.value.override_dlq_queue_policy_documents
  dlq_redrive_allow_policy              = each.value.dlq_redrive_allow_policy
  redrive_policy                        = each.value.redrive_policy
  tags                                  = local.tags
}

module "dlq_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 5.4.0"
  for_each = {
    for key, queue in local.sqs_map : key => queue
    if queue.create_dlq
  }
  create_metric_alarm = var.sns_topic_arn != "" ? true : false
  alarm_name          = module.sqs[each.key].dead_letter_queue_name
  alarm_description   = "Items are on the ${module.sqs[each.key].dead_letter_queue_name} queue"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  period              = 300
  statistic           = "Average"
  treat_missing_data  = "notBreaching"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  dimensions = {
    "QueueName" : module.sqs[each.key].dead_letter_queue_name
  }
  alarm_actions = [var.sns_topic_arn]
  tags          = local.tags
}
