
locals {
  default_settings = {
    server_memory_size                      = 1024
    image_optimisation_memory_size          = 1024
    server_cloudwatch_log_retention_in_days = 1
    # This represents the maximum number of concurrent instances allocated to your function. When a function has reserved concurrency, no other function can use that concurrency. Configuring reserved concurrency for a function incurs no additional charges.
    # A value of 0 disables Lambda Function from being triggered, -1 removes any concurrency limitations. Defaults to Unreserved Concurrency Limits -1
    server_reserved_concurrent_executions = -1
    image_reserved_concurrent_executions  = -1
    provisioned_concurrent_executions     = -1
    schedule_expression                   = "rate(15 minutes)"
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
        server_memory_size                      = 1024
        image_optimisation_memory_size          = 1024
        server_cloudwatch_log_retention_in_days = 14
        provisioned_concurrent_executions       = 2
        schedule_expression                     = "rate(5 minutes)"
      }
    )
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  merged_settings = {
    server_memory_size                      = coalesce(var.server_memory_size, local.merged_default_settings.server_memory_size)
    image_optimisation_memory_size          = coalesce(var.image_optimisation_memory_size, local.merged_default_settings.image_optimisation_memory_size)
    server_cloudwatch_log_retention_in_days = coalesce(var.server_cloudwatch_log_retention_in_days, local.merged_default_settings.server_cloudwatch_log_retention_in_days)
    server_reserved_concurrent_executions   = coalesce(var.server_reserved_concurrent_executions, local.merged_default_settings.server_reserved_concurrent_executions)
    image_reserved_concurrent_executions    = coalesce(var.image_reserved_concurrent_executions, local.merged_default_settings.image_reserved_concurrent_executions)
    schedule_expression                     = coalesce(var.schedule_expression, local.merged_default_settings.schedule_expression)
  }
}


module "lambda_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "~> 5.1.0"
  create      = var.vpc_id == "" ? false : true
  name        = "${local.name}-server-sg"
  description = "Lambda ${local.name}-server Security group"
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  vpc_id = var.vpc_id
}


module "server" {
  source                            = "terraform-aws-modules/lambda/aws"
  version                           = "~> 6.0.1"
  function_name                     = "${local.name}-server"
  description                       = "Open Next Server Function"
  handler                           = "index.handler"
  runtime                           = "nodejs18.x"
  memory_size                       = local.merged_settings.server_memory_size
  timeout                           = 30
  cloudwatch_logs_retention_in_days = local.merged_settings.server_cloudwatch_log_retention_in_days
  reserved_concurrent_executions    = local.merged_settings.server_reserved_concurrent_executions
  architectures                     = ["x86_64"]
  create_package                    = false
  ignore_source_code_hash           = true
  create_lambda_function_url        = true
  vpc_subnet_ids                    = var.vpc_id == "" ? null : var.subnet_ids
  vpc_security_group_ids            = var.vpc_id == "" ? [] : [module.lambda_sg.security_group_id]
  attach_network_policy             = var.vpc_id == "" ? false : true
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
    } : {},
    var.server_environment_variables,
    local.secret_vars_env,
  )
  attach_policy_statements = length(var.policy_statements) > 0 ? true : false
  policy_statements        = var.policy_statements
  attach_policy_json       = true
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
          "cloudfront:CreateInvalidation",
        ],
        Resource = ["*"]
      },
      {
        Effect = "Allow",
        Action = [
          "ivs:BatchGetChannel",
          "ivs:BatchGetStreamKey",
          "ivs:CreateRecordingConfiguration",
          "ivs:GetChannel",
          "ivs:GetParticipant",
          "ivs:GetRecordingConfiguration",
          "ivs:GetStream",
          "ivs:GetStreamKey",
          "ivs:GetStreamSession",
          "ivs:ListChannels",
          "ivs:ListParticipantEvents",
          "ivs:ListParticipants",
          "ivs:ListRecordingConfigurations",
          "ivs:ListStreamKeys",
          "ivs:ListStreamSessions",
          "ivs:ListStreams",
          "ivschat:CreateChatToken",
          "ivschat:DeleteMessage",
          "ivschat:DisconnectUser",
          "ivschat:GetRoom",
          "ivschat:ListRooms",
          "ivschat:SendEvent",
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
      "cloudfront:GetInvalidation",
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
  memory_size                       = local.merged_settings.image_optimisation_memory_size # 1536
  timeout                           = 25
  cloudwatch_logs_retention_in_days = 1
  reserved_concurrent_executions    = local.merged_settings.image_reserved_concurrent_executions
  # https://github.com/sst/open-next/blob/main/packages/open-next/src/build.ts#L375
  architectures              = ["arm64"]
  create_package             = false
  ignore_source_code_hash    = true
  create_lambda_function_url = true
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
        Resource = compact(distinct(concat([
          "${module.s3_bucket.s3_bucket_arn}/*"
        ], var.image_optimisation_s3_bucket_arns)))
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
  content_based_deduplication = true
  sqs_managed_sse_enabled     = true
  # https://github.com/sst/sst/blob/master/packages/sst/src/constructs/NextjsSite.ts#L424
  receive_wait_time_seconds = 20
}

resource "aws_lambda_event_source_mapping" "revalidation_queue_source" {
  function_name    = module.revalidation.lambda_function_arn
  event_source_arn = aws_sqs_queue.revalidation_queue.arn
  # https://github.com/sst/sst/blob/master/packages/sst/src/constructs/NextjsSite.ts#L436
  batch_size = 5
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
  architectures                     = ["x86_64"]
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

# https://github.com/sst/sst/blob/master/packages/sst/src/constructs/SsrSite.ts#L729
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
  # https://github.com/sst/open-next/blob/main/packages/open-next/src/build.ts#L375
  architectures              = ["x86_64"]
  create_package             = false
  ignore_source_code_hash    = true
  create_lambda_function_url = true
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
  schedule_expression = local.merged_settings.schedule_expression
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

data "aws_secretsmanager_secret" "secret" {
  for_each = var.secret_vars
  name     = each.value.secret_path
}

data "aws_secretsmanager_secret_version" "secret" {
  for_each  = var.secret_vars
  secret_id = data.aws_secretsmanager_secret.secret[each.key].id
}

locals {
  secret_vars_env = {
    for k, v in var.secret_vars : k =>
    jsondecode(nonsensitive(data.aws_secretsmanager_secret_version.secret[k].secret_string))[v.property] if length(var.secret_vars) > 0
  }
}
