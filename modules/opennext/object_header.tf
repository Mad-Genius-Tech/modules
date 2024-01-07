
module "object_header" {
  source                            = "terraform-aws-modules/lambda/aws"
  version                           = "~> 6.5.0"
  function_name                     = "${local.name}-object-header"
  description                       = "Open Next S3 assets headers update"
  handler                           = "index.lambda_handler"
  runtime                           = "python3.11"
  memory_size                       = 128
  timeout                           = 10
  cloudwatch_logs_retention_in_days = 1
  architectures                     = ["arm64"]
  source_path                       = "./src"
  environment_variables = {
    "S3_BUCKET_NAME" = module.s3_bucket.s3_bucket_id
  }
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
    ]
  })
  tags = local.tags
}

resource "aws_s3_bucket_notification" "object_lambda_trigger" {
  bucket = module.s3_bucket.s3_bucket_id
  lambda_function {
    lambda_function_arn = module.object_header.lambda_function_arn
    events = [
      "s3:ObjectCreated:Put",
    ]
    filter_prefix = "_assets/"
  }
}

resource "aws_lambda_permission" "object_lambda_permission" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = module.object_header.lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3_bucket.s3_bucket_arn
}