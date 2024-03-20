
variable "sqs" {
  type = map(object({
    create                     = optional(bool)
    fifo_queue                 = optional(bool)
    create_queue_policy        = optional(bool)
    visibility_timeout_seconds = optional(number)
    create_dlq                 = optional(bool)
    create_dlq_queue_policy    = optional(bool)
    redrive_policy             = optional(map(string))
  }))
  default = {}
}