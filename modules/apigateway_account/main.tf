# Settings is applied region-wide per provider block
resource "aws_api_gateway_account" "apigateway_account" {
  count               = var.create ? 1 : 0
  cloudwatch_role_arn = join("", aws_iam_role.apigateway_cloudwatch_logs[*].arn)
}

resource "aws_iam_role" "apigateway_cloudwatch_logs" {
  count              = var.create ? 1 : 0
  name               = "${module.context.id}-logs"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags               = local.tags
}

resource "aws_iam_role_policy" "apigateway_cloudwatch_logs" {
  count  = var.create ? 1 : 0
  name   = "${module.context.id}-logs"
  role   = join("", aws_iam_role.apigateway_cloudwatch_logs[*].id)
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
