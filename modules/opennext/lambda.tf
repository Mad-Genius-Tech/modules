
module "server" {
  source                            = "terraform-aws-modules/lambda/aws"
  version                           = "~> 6.0.1"
  function_name                     = "${local.name}-server"
  description                       = "Open Next Server Function"
  handler                           = "index.handler"
  runtime                           = "nodejs18.x"
  memory_size                       = 1024
  timeout                           = 10 # 30
  cloudwatch_logs_retention_in_days = 1
  architectures                     = ["arm64"]
  create_package                    = false
  ignore_source_code_hash           = true
  create_lambda_function_url        = true
  s3_existing_package = {
    bucket = module.s3_bucket.s3_bucket_id
    key    = aws_s3_object.s3_object_placeholder.id
  }
  environment_variables = merge(
    {
      "CACHE_BUCKET_NAME" : module.s3_bucket.s3_bucket_id
      "CACHE_BUCKET_KEY_PREFIX" : "_cache",
      "CACHE_BUCKET_REGION" : data.aws_region.current.name,
      "REVALIDATION_QUEUE_URL" : aws_sqs_queue.revalidation_queue.url,
      "REVALIDATION_QUEUE_REGION" : data.aws_region.current.name,
    },
    var.enable_dynamodb_cache ? {
      "CACHE_DYNAMO_TABLE" : aws_dynamodb_table.revalidation[0].name
    } : {}
  )
  attach_policy_json = true

  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject*",
          "s3:GetBucket*",
          "s3:List*",
          "s3:DeleteObject*",
          "s3:PutObject",
          "s3:PutObjectLegalHold",
          "s3:PutObjectRetention",
          "s3:PutObjectTagging",
          "s3:PutObjectVersionTagging",
          "s3:Abort*"
        ],
        Resource = [
          "${module.s3_bucket.s3_bucket_arn}",
          "${module.s3_bucket.s3_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ],
        Resource = ["${aws_sqs_queue.revalidation_queue.arn}"]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject*"
        ],
        Resource = ["${module.s3_bucket_lambda.s3_bucket_arn}/*"]
      },
      {
        Effect = "Allow",
        Action = [
          "ivs:*",
          "ivschat:*",
          # "ivs:GetStreamSession",
          # "ivs:GetChannel",
          # "ivs:GetParticipant",
          # "ivs:BatchGetChannel",
          # "ivs:ListStreamSessions",
          # "ivs:GetStreamKey",
          # "ivs:ListStreams",
          # "ivschat:ListRooms",
          # "ivschat:DeleteMessage",
          # "ivs:ListChannels",
          # "ivschat:CreateChatToken",
          # "ivs:ListParticipants",
          # "ivschat:DisconnectUser",
          # "ivs:GetStream",
          # "ivs:ListParticipantEvents",
          # "ivschat:GetRoom",
          # "ivs:BatchGetStreamKey",
          # "ivs:ListStreamKeys",
          # "ivschat:SendEvent"
        ],
        Resource = "*"
      }
    ]
  })
  tags = local.tags
}

data "aws_iam_policy_document" "server_lambda_cloudfront" {
  statement {
    actions = [
      "cloudfront:CreateInvalidation"
    ]
    resources = [
      aws_cloudfront_distribution.website_distribution.arn
    ]
  }
}

data "aws_iam_policy_document" "server_lambda_dynamodb" {
  count = var.enable_dynamodb_cache ? 1 : 0
  statement {
    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:Query",
      "dynamodb:GetItem",
      "dynamodb:Scan",
      "dynamodb:ConditionCheckItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable"
    ]
    resources = [
      aws_dynamodb_table.revalidation[0].arn,
      "${aws_dynamodb_table.revalidation[0].arn}/index/*"
    ]
  }
}

resource "aws_iam_role_policy" "server_lambda_cloudfront" {
  name   = "${module.server.lambda_role_name}-cloudfront"
  role   = module.server.lambda_role_name
  policy = data.aws_iam_policy_document.server_lambda_cloudfront.json
}

resource "aws_iam_role_policy" "server_lambda_dynamodb" {
  count  = var.enable_dynamodb_cache ? 1 : 0
  name   = "${module.server.lambda_role_name}-dynamodb"
  role   = module.server.lambda_role_name
  policy = data.aws_iam_policy_document.server_lambda_dynamodb[0].json
}

# https://github.com/sst/sst/blob/master/packages/sst/src/constructs/SsrSite.ts#L989
module "image_optimisation" {
  source                            = "terraform-aws-modules/lambda/aws"
  version                           = "~> 6.0.1"
  function_name                     = "${local.name}-image-optimization"
  description                       = "Open Next Image Optimization Function"
  handler                           = "index.handler"
  runtime                           = "nodejs18.x"
  memory_size                       = 1536 # default 1024 MB
  timeout                           = 25
  cloudwatch_logs_retention_in_days = 1
  architectures                     = ["arm64"]
  create_package                    = false
  ignore_source_code_hash           = true
  create_lambda_function_url        = true
  s3_existing_package = {
    bucket = module.s3_bucket.s3_bucket_id
    key    = aws_s3_object.s3_object_placeholder.id
  }
  environment_variables = {
    "BUCKET_KEY_PREFIX" = "_assets"
    "BUCKET_NAME"       = module.s3_bucket.s3_bucket_id
  }
  attach_policy_json = true
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject"
        ],
        Resource = [
          "${module.s3_bucket.s3_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject*"
        ],
        Resource = [
          "${module.s3_bucket_lambda.s3_bucket_arn}/*"
        ]
      }
    ]
  })
  tags = local.tags
}

resource "aws_sqs_queue" "revalidation_queue" {
  name                        = "${local.name}-isr-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = false
  receive_wait_time_seconds   = 20
}

resource "aws_lambda_event_source_mapping" "revalidation_queue_source" {
  function_name    = module.revalidation.lambda_function_arn
  event_source_arn = aws_sqs_queue.revalidation_queue.arn
  batch_size       = 5
}

module "revalidation_insert" {
  source                            = "terraform-aws-modules/lambda/aws"
  version                           = "~> 6.0.1"
  create                            = var.enable_dynamodb_cache
  function_name                     = "${local.name}-revalidation-insert"
  description                       = "Open Next Revalidation Data Insert Function"
  handler                           = "index.handler"
  runtime                           = "nodejs18.x"
  memory_size                       = 128
  timeout                           = 15 * 60
  cloudwatch_logs_retention_in_days = 1
  create_package                    = false
  ignore_source_code_hash           = true
  create_lambda_function_url        = false
  s3_existing_package = {
    bucket = module.s3_bucket.s3_bucket_id
    key    = aws_s3_object.s3_object_placeholder.id
  }
  environment_variables = {
    "CACHE_DYNAMO_TABLE" : var.enable_dynamodb_cache ? aws_dynamodb_table.revalidation[0].name : ""
  }
  attach_policy_json = true
  policy_json        = <<-EOT
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "dynamodb:BatchWriteItem",
            "dynamodb:PutItem",
            "dynamodb:DescribeTable"
          ],
          "Resource": ["${var.enable_dynamodb_cache ? aws_dynamodb_table.revalidation[0].arn : "*"}"]
        },
        {
          "Effect": "Allow",
          "Action": [
            "s3:GetObject*"
          ],
          "Resource": ["${module.s3_bucket_lambda.s3_bucket_arn}/*"]
        }
      ]
    }
  EOT
  tags               = local.tags
}

module "revalidation" {
  source                            = "terraform-aws-modules/lambda/aws"
  version                           = "~> 6.0.1"
  function_name                     = "${local.name}-revalidation"
  description                       = "Open Next Revalidation Function"
  handler                           = "index.handler"
  runtime                           = "nodejs18.x"
  memory_size                       = 128
  timeout                           = 30
  cloudwatch_logs_retention_in_days = 1
  create_package                    = false
  ignore_source_code_hash           = true
  create_lambda_function_url        = false
  s3_existing_package = {
    bucket = module.s3_bucket.s3_bucket_id
    key    = aws_s3_object.s3_object_placeholder.id
  }
  attach_policy_json = true
  policy_json        = <<-EOT
    {
        "Version": "2012-10-17",
        "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                "sqs:ReceiveMessage",
                "sqs:ChangeMessageVisibility",
                "sqs:GetQueueUrl",
                "sqs:DeleteMessage",
                "sqs:GetQueueAttributes"
              ],
              "Resource": ["${aws_sqs_queue.revalidation_queue.arn}"]
          },
          {
            "Effect": "Allow",
            "Action": [
              "s3:GetObject*"
            ],
            "Resource": ["${module.s3_bucket_lambda.s3_bucket_arn}/*"]
          }
        ]
    }
  EOT
  tags               = local.tags
}

# https://github.com/sst/sst/blob/master/packages/sst/src/constructs/SsrSite.ts#L677
module "warmer" {
  source                            = "terraform-aws-modules/lambda/aws"
  version                           = "~> 6.0.1"
  function_name                     = "${local.name}-warmer"
  description                       = "Open Next Warmer Function"
  handler                           = "index.handler"
  runtime                           = "nodejs18.x"
  memory_size                       = 128
  timeout                           = 15 * 60
  cloudwatch_logs_retention_in_days = 1
  architectures                     = ["arm64"]
  create_package                    = false
  ignore_source_code_hash           = true
  create_lambda_function_url        = true
  s3_existing_package = {
    bucket = module.s3_bucket.s3_bucket_id
    key    = aws_s3_object.s3_object_placeholder.id
  }
  environment_variables = {
    "FUNCTION_NAME" : module.server.lambda_function_name
    "CONCURRENCY" : 1
  }
  attach_policy_json = true
  policy_json        = <<-EOT
    {
        "Version": "2012-10-17",
        "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                "lambda:InvokeFunction"
              ],
              "Resource": ["${module.server.lambda_function_arn}"]
          },
          {
            "Effect": "Allow",
            "Action": [
              "s3:GetObject*"
            ],
            "Resource": ["${module.s3_bucket_lambda.s3_bucket_arn}/*"]
          }
        ]
    }
  EOT
  tags               = local.tags
}

resource "aws_cloudwatch_event_rule" "cron" {
  name                = "${local.name}-cron"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda" {
  target_id = "lambda"
  arn       = module.warmer.lambda_function_arn
  rule      = aws_cloudwatch_event_rule.cron.name
}

resource "aws_lambda_permission" "eventbridge_invoke" {
  statement_id  = "AllowExecutionFromEventbridge"
  action        = "lambda:InvokeFunction"
  function_name = module.warmer.lambda_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron.arn
}