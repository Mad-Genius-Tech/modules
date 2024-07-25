data "aws_canonical_user_id" "current" {}
data "aws_cloudfront_log_delivery_canonical_user_id" "awslogsdelivery" {}

module "cloudfront_logs" {
  create_bucket            = var.cloudfront_logging_enabled ? true : false
  source                   = "terraform-aws-modules/s3-bucket/aws"
  version                  = "~> 4.1.2"
  control_object_ownership = true
  object_ownership         = "ObjectWriter"
  # https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html#AccessLogsBucketAndFileOwnership  
  grant = {
    "current" = {
      permission = "FULL_CONTROL"
      type       = "CanonicalUser"
      id         = data.aws_canonical_user_id.current.id
    },
    "awslogsdelivery" = {
      permission = "FULL_CONTROL"
      type       = "CanonicalUser"
      id         = data.aws_cloudfront_log_delivery_canonical_user_id.awslogsdelivery.id
    }
  }
  bucket = "${local.name}-logs"
  tags   = local.tags
}

resource "aws_s3_bucket_notification" "logs_notification" {
  count  = var.cloudfront_logging_enabled ? 1 : 0
  bucket = module.cloudfront_logs.s3_bucket_id
  lambda_function {
    lambda_function_arn = module.cloudfront_logs_forward.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
  }
}

module "cloudfront_logs_forward" {
  create                            = var.cloudfront_logging_enabled
  source                            = "terraform-aws-modules/lambda/aws"
  version                           = "~> 6.0.1"
  function_name                     = "${local.name}-cloudfront-logs"
  description                       = "Open Next Cloudfront logs forwarder"
  handler                           = "index.handler"
  runtime                           = "nodejs18.x"
  memory_size                       = 512
  timeout                           = 60
  cloudwatch_logs_retention_in_days = 1
  architectures                     = ["x86_64"]
  source_path                       = "./src/cloudfront_logging/index.js"
  environment_variables = {
    LOG_GROUP_NAME   = join("", aws_cloudwatch_log_group.target_log_group[*].name)
    LOG_GROUP_REGION = data.aws_region.current.name
  }
  attach_policy_json = true
  policy_json        = <<-EOT
    {
      "Version": "2012-10-17",
      "Statement": [
        {
            "Effect": "Allow",
            "Action": ["s3:Get*", "s3:List*"],
            "Resource": [
              "${module.cloudfront_logs.s3_bucket_arn}",
              "${module.cloudfront_logs.s3_bucket_arn}/*"
            ]
        },
        {
          "Effect": "Allow",
          "Action": [
            "logs:CreateLogGroup", 
            "logs:CreateLogStream", 
            "logs:PutLogEvents",
            "logs:DescribeLogStreams"
          ],
          "Resource": [
            "${join("", aws_cloudwatch_log_group.target_log_group[*].arn)}*"
          ]
        }
      ]
    }
  EOT
  tags               = local.tags
}

resource "aws_cloudwatch_log_group" "target_log_group" {
  count             = var.cloudfront_logging_enabled ? 1 : 0
  name              = "/aws/cloudfront/${local.name}-logs"
  retention_in_days = var.cloudfront_log_retention_period
}

resource "aws_lambda_permission" "s3_bucket_invoke_function" {
  count         = var.cloudfront_logging_enabled ? 1 : 0
  function_name = module.cloudfront_logs_forward.lambda_function_name
  action        = "lambda:InvokeFunction"
  principal     = "s3.amazonaws.com"
  source_arn    = module.cloudfront_logs.s3_bucket_arn
}
