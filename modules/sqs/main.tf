
locals {
  default_settings = {
    fifo_queue                 = false
    use_name_prefix            = false
    create_queue_policy        = false
    create_dlq                 = true
    create_dlq_queue_policy    = false
    redrive_policy             = {}
    visibility_timeout_seconds = 30
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
      "identifier"                 = "${module.context.id}-${k}"
      "create"                     = coalesce(lookup(v, "create", null), true)
      "fifo_queue"                 = try(coalesce(lookup(v, "fifo_queue", null), local.merged_default_settings.fifo_queue), local.merged_default_settings.fifo_queue)
      "create_queue_policy"        = try(coalesce(lookup(v, "create_queue_policy", null), local.merged_default_settings.create_queue_policy), local.merged_default_settings.create_queue_policy)
      "visibility_timeout_seconds" = try(coalesce(lookup(v, "visibility_timeout_seconds", null), local.merged_default_settings.visibility_timeout_seconds), local.merged_default_settings.visibility_timeout_seconds)
      "create_dlq"                 = try(coalesce(lookup(v, "create_dlq", null), local.merged_default_settings.create_dlq), local.merged_default_settings.create_dlq)
      "create_dlq_queue_policy"    = try(coalesce(lookup(v, "create_dlq_queue_policy", null), local.merged_default_settings.create_dlq_queue_policy), local.merged_default_settings.create_dlq_queue_policy)
      "redrive_policy"             = try(coalesce(lookup(v, "redrive_policy", null), local.merged_default_settings.redrive_policy), local.merged_default_settings.redrive_policy)

    } if coalesce(lookup(v, "create", null), true)
  }
}

module "sqs" {
  source                     = "terraform-aws-modules/sqs/aws"
  version                    = "~> 4.1.1"
  for_each                   = local.sqs_map
  name                       = each.value.identifier
  fifo_queue                 = each.value.fifo_queue
  visibility_timeout_seconds = each.value.visibility_timeout_seconds
  create_queue_policy        = each.value.create_queue_policy
  create_dlq                 = each.value.create_dlq
  create_dlq_queue_policy    = each.value.create_dlq_queue_policy
  redrive_policy             = each.value.redrive_policy
  tags                       = local.tags
}