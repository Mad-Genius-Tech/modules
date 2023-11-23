resource "aws_iam_role" "iam_role" {
  name               = module.context.id
  description        = "IAM role for AWS Synthetic Monitoring Canaries"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.iam_role.name
  policy_arn = aws_iam_policy.canary_policy.arn
}

resource "aws_iam_policy" "canary_policy" {
  name        = module.context.id
  description = "Cloudwatch Synthetics Canary Policy"
  policy      = data.aws_iam_policy_document.canary_policy.json
}

data "aws_iam_policy_document" "canary_policy" {
  statement {
    effect = "Allow"
    resources = [
      "${module.s3_bucket.s3_bucket_arn}/*",
    ]
    actions = ["s3:PutObject"]
  }
  statement {
    effect = "Allow"
    resources = [
      module.s3_bucket.s3_bucket_arn,
    ]
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]
  }
  statement {
    effect = "Allow"
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"
    ]
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup",
    ]
  }
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "s3:ListAllMyBuckets",
      "xray:PutTraceSegments",
    ]
  }
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["cloudwatch:PutMetricData"]
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["CloudWatchSynthetics"]
    }
  }
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.15.1"
  bucket  = module.context.id
  versioning = {
    enabled = true
  }
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  lifecycle_rule = [
    {
      id                                     = "log"
      enabled                                = true
      abort_incomplete_multipart_upload_days = 1
      noncurrent_version_expiration = {
        days = 3
      }
    }
  ]
}