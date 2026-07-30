
variable "sqs" {
  type = map(object({
    create                                = optional(bool)
    fifo_queue                            = optional(bool)
    use_name_prefix                       = optional(bool)
    create_queue_policy                   = optional(bool)
    visibility_timeout_seconds            = optional(number)
    message_retention_seconds             = optional(number)
    receive_wait_time_seconds             = optional(number)
    max_receive_count                     = optional(number)
    redrive_policy                        = optional(map(any))
    sqs_managed_sse_enabled               = optional(bool)
    kms_master_key_id                     = optional(string)
    kms_data_key_reuse_period_seconds     = optional(number)
    queue_policy_statements               = optional(any)
    source_queue_policy_documents         = optional(list(string))
    override_queue_policy_documents       = optional(list(string))
    create_dlq                            = optional(bool)
    create_dlq_queue_policy               = optional(bool)
    create_dlq_redrive_allow_policy       = optional(bool)
    dlq_message_retention_seconds         = optional(number)
    dlq_receive_wait_time_seconds         = optional(number)
    dlq_visibility_timeout_seconds        = optional(number)
    dlq_sqs_managed_sse_enabled           = optional(bool)
    dlq_kms_master_key_id                 = optional(string)
    dlq_kms_data_key_reuse_period_seconds = optional(number)
    dlq_queue_policy_statements           = optional(any)
    source_dlq_queue_policy_documents     = optional(list(string))
    override_dlq_queue_policy_documents   = optional(list(string))
    dlq_redrive_allow_policy              = optional(any)
  }))
  default = {}

  validation {
    condition = alltrue([
      for queue in values(var.sqs) :
      try(
        queue.message_retention_seconds >= 60 && queue.message_retention_seconds <= 1209600,
        true,
      )
    ])
    error_message = "message_retention_seconds must be between 60 seconds and 14 days (1209600 seconds)."
  }

  validation {
    condition = alltrue([
      for queue in values(var.sqs) :
      try(
        queue.dlq_message_retention_seconds >= 60 && queue.dlq_message_retention_seconds <= 1209600,
        true,
      )
    ])
    error_message = "dlq_message_retention_seconds must be between 60 seconds and 14 days (1209600 seconds)."
  }

  validation {
    condition = alltrue([
      for queue in values(var.sqs) :
      try(
        queue.receive_wait_time_seconds >= 0 && queue.receive_wait_time_seconds <= 20,
        true,
      )
    ])
    error_message = "receive_wait_time_seconds must be between 0 and 20 seconds."
  }

  validation {
    condition = alltrue([
      for queue in values(var.sqs) :
      try(
        queue.dlq_receive_wait_time_seconds >= 0 && queue.dlq_receive_wait_time_seconds <= 20,
        true,
      )
    ])
    error_message = "dlq_receive_wait_time_seconds must be between 0 and 20 seconds."
  }

  validation {
    condition = alltrue([
      for queue in values(var.sqs) :
      try(
        queue.visibility_timeout_seconds >= 0 && queue.visibility_timeout_seconds <= 43200,
        true,
      )
    ])
    error_message = "visibility_timeout_seconds must be between 0 and 43200 seconds."
  }

  validation {
    condition = alltrue([
      for queue in values(var.sqs) :
      try(
        queue.dlq_visibility_timeout_seconds >= 0 && queue.dlq_visibility_timeout_seconds <= 43200,
        true,
      )
    ])
    error_message = "dlq_visibility_timeout_seconds must be between 0 and 43200 seconds."
  }

  validation {
    condition = alltrue([
      for queue in values(var.sqs) :
      try(
        queue.max_receive_count >= 1 && queue.max_receive_count <= 1000 && floor(queue.max_receive_count) == queue.max_receive_count,
        true,
      )
    ])
    error_message = "max_receive_count must be a whole number between 1 and 1000."
  }

  validation {
    condition = alltrue([
      for queue in values(var.sqs) :
      try(
        queue.kms_data_key_reuse_period_seconds >= 60 && queue.kms_data_key_reuse_period_seconds <= 86400,
        true,
      )
    ])
    error_message = "kms_data_key_reuse_period_seconds must be between 60 and 86400 seconds."
  }

  validation {
    condition = alltrue([
      for queue in values(var.sqs) :
      try(
        queue.dlq_kms_data_key_reuse_period_seconds >= 60 && queue.dlq_kms_data_key_reuse_period_seconds <= 86400,
        true,
      )
    ])
    error_message = "dlq_kms_data_key_reuse_period_seconds must be between 60 and 86400 seconds."
  }
}

variable "sns_topic_arn" {
  type    = string
  default = ""
}
