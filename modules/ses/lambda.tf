module "contact_export" {
  source                            = "terraform-aws-modules/lambda/aws"
  version                           = "~> 6.0.1"
  create                            = var.contact_list_name != ""
  function_name                     = "${module.context.id}-contact-export"
  description                       = "SES Contact Export"
  handler                           = "index.lambda_handler"
  runtime                           = "python3.12"
  memory_size                       = 512
  timeout                           = 60
  cloudwatch_logs_retention_in_days = 1
  architectures                     = ["arm64"]
  create_package                    = true
  source_path                       = "contacts-export"
  create_lambda_function_url        = true
  environment_variables = {
    "CONTACT_LIST_NAME" : "ContactList",
    "TOPIC_NAME" : "fanclub-waitlist",
  }
  attach_policy_json = true
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ses:ListContacts",
          "ses:ListContactLists",
        ],
        Resource = [
          "*"
        ]
      }
    ]
  })
  tags = local.tags
}

module "ses_notifications" {
  source                            = "terraform-aws-modules/lambda/aws"
  version                           = "~> 6.0.1"
  create                            = var.ses_domain_name != ""
  function_name                     = "${module.context.id}-notification"
  description                       = "SES Notification"
  handler                           = "index.lambda_handler"
  runtime                           = "python3.12"
  memory_size                       = 512
  timeout                           = 60
  cloudwatch_logs_retention_in_days = 1
  architectures                     = ["arm64"]
  create_package                    = true
  source_path                       = "ses_notifications"
  environment_variables = {
    "SES_TABLE_NAME" : aws_dynamodb_table.ses_notifications.name,
  }
  attach_policy_json = true
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sqs:ChangeMessageVisibility",
          "sqs:ChangeMessageVisibilityBatch",
          "sqs:DeleteMessage",
          "sqs:DeleteMessageBatch",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage"
        ],
        Resource = [
          aws_sqs_queue.queue.arn
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ],
        Resource = [
          aws_dynamodb_table.ses_notifications.arn
        ]
      }
    ]
  })
  tags = local.tags
}

resource "aws_dynamodb_table" "ses_notifications" {
  name         = "SESNotifications"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "SESMessageId"
  range_key    = "SnsPublishTime"

  attribute {
    name = "SESMessageId"
    type = "S"
  }
  attribute {
    name = "SnsPublishTime"
    type = "S"
  }
  attribute {
    name = "SESMessageType"
    type = "S"
  }
  attribute {
    name = "SESComplaintFeedbackType"
    type = "S"
  }

  global_secondary_index {
    name            = "SESMessageType-Index"
    hash_key        = "SESMessageType"
    range_key       = "SnsPublishTime"
    projection_type = "ALL"
  }
  global_secondary_index {
    name            = "SESMessageComplaintType-Index"
    hash_key        = "SESComplaintFeedbackType"
    range_key       = "SnsPublishTime"
    projection_type = "ALL"
  }
  tags = local.tags
}