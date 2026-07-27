mock_provider "aws" {
  alias = "contract"
}

run "primary_and_dlq_contract_defaults" {
  command = plan

  providers = {
    aws = aws.contract
  }

  variables {
    org_name     = "example"
    stage_name   = "dev"
    service_name = "worker"
    team_name    = "platform"
    tags = {
      owner = "platform"
    }
    sqs = {
      delivery = {}
    }
  }

  assert {
    condition     = contains(keys(output.queue_arns), "delivery") && contains(keys(output.queue_urls), "delivery")
    error_message = "The module must expose primary queue ARN and URL outputs for every queue."
  }

  assert {
    condition     = contains(keys(output.dlq_arns), "delivery") && contains(keys(output.dlq_urls), "delivery")
    error_message = "The module must expose DLQ ARN and URL outputs for every queue."
  }

  assert {
    condition = (
      local.sqs_map.delivery.message_retention_seconds == 1209600 &&
      local.sqs_map.delivery.dlq_message_retention_seconds == 1209600 &&
      local.sqs_map.delivery.receive_wait_time_seconds == 20 &&
      local.sqs_map.delivery.dlq_receive_wait_time_seconds == 20 &&
      local.sqs_map.delivery.redrive_policy.maxReceiveCount == 5 &&
      local.sqs_map.delivery.sqs_managed_sse_enabled &&
      local.sqs_map.delivery.dlq_sqs_managed_sse_enabled
    )
    error_message = "Default primary and DLQ retention, long polling, redrive, and encryption controls must be safe."
  }
}

run "custom_delivery_controls_are_accepted" {
  command = plan

  providers = {
    aws = aws.contract
  }

  variables {
    org_name     = "example"
    stage_name   = "dev"
    service_name = "worker"
    team_name    = "platform"
    sqs = {
      delivery = {
        message_retention_seconds     = 1209600
        dlq_message_retention_seconds = 1209600
        receive_wait_time_seconds     = 20
        visibility_timeout_seconds    = 120
        max_receive_count             = 7
        kms_master_key_id             = "alias/example-queue"
        queue_policy_statements = {
          consumer = {
            effect  = "Allow"
            actions = ["sqs:ReceiveMessage", "sqs:DeleteMessage"]
            principals = [{
              type        = "AWS"
              identifiers = ["arn:aws:iam::123456789012:role/consumer"]
            }]
          }
        }
      }
    }
  }

  assert {
    condition = (
      local.sqs_map.delivery.visibility_timeout_seconds == 120 &&
      local.sqs_map.delivery.redrive_policy.maxReceiveCount == 7 &&
      local.sqs_map.delivery.kms_master_key_id == "alias/example-queue" &&
      local.sqs_map.delivery.queue_policy_statements.consumer.actions == ["sqs:ReceiveMessage", "sqs:DeleteMessage"]
    )
    error_message = "Explicit consumer controls must reach the queue module unchanged."
  }
}

run "invalid_delivery_controls_are_rejected" {
  command = plan

  providers = {
    aws = aws.contract
  }

  variables {
    org_name     = "example"
    stage_name   = "dev"
    service_name = "worker"
    team_name    = "platform"
    sqs = {
      delivery = {
        message_retention_seconds = 1209601
      }
    }
  }

  expect_failures = [var.sqs]
}

run "queue_without_a_dlq_keeps_its_existing_no_redrive_default" {
  command = plan

  providers = {
    aws = aws.contract
  }

  variables {
    org_name     = "example"
    stage_name   = "dev"
    service_name = "worker"
    team_name    = "platform"
    sqs = {
      direct = {
        create_dlq = false
      }
    }
  }

  assert {
    condition     = length(local.sqs_map.direct.redrive_policy) == 0
    error_message = "Queues that opt out of a DLQ must retain the existing empty redrive policy by default."
  }
}
