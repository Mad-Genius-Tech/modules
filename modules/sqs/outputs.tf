output "queue_arns" {
  description = "ARNs for primary queues, keyed by the caller's sqs map key."
  value = {
    for key, queue in module.sqs : key => queue.queue_arn
  }
}

output "queue_urls" {
  description = "URLs for primary queues, keyed by the caller's sqs map key."
  value = {
    for key, queue in module.sqs : key => queue.queue_url
  }
}

output "dlq_arns" {
  description = "ARNs for dead-letter queues, keyed by the caller's sqs map key. Values are null when create_dlq is false."
  value = {
    for key, queue in module.sqs : key => queue.dead_letter_queue_arn
  }
}

output "dlq_urls" {
  description = "URLs for dead-letter queues, keyed by the caller's sqs map key. Values are null when create_dlq is false."
  value = {
    for key, queue in module.sqs : key => queue.dead_letter_queue_url
  }
}
