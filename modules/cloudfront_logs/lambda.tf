locals {
  name = module.context.id
}

resource "aws_lambda_function" "transform_partition" {
  filename      = "src/transformPartition.zip"
  function_name = "${local.name}-accesslogs-transform-partition"
  role          = aws_iam_role.lambda_role.arn
  handler       = "transformPartition.handler"
  runtime       = "nodejs20.x"
  timeout       = 900
  environment {
    variables = {
      SOURCE_TABLE                  = aws_glue_catalog_table.partitioned_gz_table.name
      TARGET_TABLE                  = aws_glue_catalog_table.partitioned_parquet_table.name
      DATABASE                      = aws_glue_catalog_database.cf_logs_database.name
      ATHENA_QUERY_RESULTS_LOCATION = "s3://${local.s3_bucket}/athena-query-results"
    }
  }
}

resource "aws_lambda_function" "create_partitions" {
  filename      = "src/createPartitions.zip"
  function_name = "${loca.name}-accesslogs-create-partitions"
  role          = aws_iam_role.lambda_role.arn
  handler       = "createPartitions.handler"
  runtime       = "nodejs20.x"
  timeout       = 300
  environment {
    variables = {
      TABLE                         = aws_glue_catalog_table.partitioned_gz_table.name
      DATABASE                      = aws_glue_catalog_database.cf_logs_database.name
      ATHENA_QUERY_RESULTS_LOCATION = "s3://${local.s3_bucket}/athena-query-results"
    }
  }
}

resource "aws_lambda_function" "move_new_access_logs" {
  filename      = "src/moveAccessLogs.zip"
  function_name = "${local.name}-accesslogs-move"
  role          = aws_iam_role.lambda_role.arn
  handler       = "moveAccessLogs.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  environment {
    variables = {
      TARGET_KEY_PREFIX = var.gz_key_prefix
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "${local.name}-accesslogs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "glue:CreatePartition",
          "glue:GetDatabase",
          "glue:GetTable",
          "glue:BatchCreatePartition",
          "glue:GetPartition",
          "glue:GetPartitions",
          "glue:CreateTable",
          "glue:DeleteTable",
          "glue:DeletePartition"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_cloudwatch_event_rule" "hourly_event" {
  name                = "${local.name}-accesslogs-hourly"
  description         = "Fires every hour"
  schedule_expression = "cron(1 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "transform_partition_target" {
  rule      = aws_cloudwatch_event_rule.hourly_event.name
  target_id = aws_lambda_function.transform_partition.function_name
  arn       = aws_lambda_function.transform_partition.arn
}

resource "aws_cloudwatch_event_rule" "hourly_event_55" {
  name                = "${local.name}-accesslogs-hourly-55"
  description         = "Fires every hour at minute 55"
  schedule_expression = "cron(55 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "create_partitions_target" {
  rule      = aws_cloudwatch_event_rule.hourly_event_55.name
  target_id = aws_lambda_function.create_partitions.function_name
  arn       = aws_lambda_function.create_partitions.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = local.s3_bucket
  lambda_function {
    lambda_function_arn = aws_lambda_function.move_new_access_logs.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.new_key_prefix
  }
}
