resource "aws_iam_role" "chime_lambda" {
  name = "${local.service_name}-chime-lambda"
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

  inline_policy {
    name = "cloudwatch-logs"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
          ]
          Effect = "Allow"
          Resource = [
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"
          ]
        }
      ]
    })
  }

  inline_policy {
    name = "chime"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "chime:CreateAppInstance",
            "chime:CreateAppInstanceAdmin",
            "chime:CreateAppInstanceUser"
          ]
          Resource = [
            "*"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "chime:CreateChannelFlow"
          ]
          Resource = [
            "arn:aws:chime:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:app-instance/*"
          ]
        }
      ]
    })
  }
}

resource "aws_iam_role_policy_attachment" "chime_lambda" {
  role       = aws_iam_role.chime_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "auth_lambda" {
  name        = "${local.service_name}-auth-lambda"
  description = "The role for the Credential Exchange Service lambda that gives AWS creds to users runs with"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "cloudwatch-logs"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
          ]
          Effect = "Allow"
          Resource = [
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"
          ]
        },
      ]
    })
  }
  inline_policy {
    name = "chime"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "chime:CreateAppInstanceUser",
            "chime:CreateAppInstanceAdmin",
            "chime:DescribeAppInstanceUser",
            "chime:DescribeAppInstanceAdmin",
          ]
          Effect   = "Allow"
          Resource = ["${local.chime_app_instance_arn}/user/*"]
        }
      ]
    })
  }
  inline_policy {
    name = "chime-all"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "chime:describeChannel",
            "chime:describeChannelMembership",
            "chime:createAttendee"
          ]
          Effect   = "Allow"
          Resource = ["*"]
        }
      ]
    })
  }
  tags = local.tags
}

resource "aws_iam_role" "auth_lambda_user" {
  name        = "${local.service_name}-auth-lambda-user"
  description = "The Role the lambda parameterizes and returns to the user"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.auth_lambda.arn
        }
      },
    ]
  })

  inline_policy {
    name = "cognito-authorized-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "mobileanalytics:PutEvents"
          ]
          Effect   = "Allow"
          Resource = ["*"]
        }
      ]
    })
  }

  inline_policy {
    name = "s3-attachments"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject"
          ]
          Resource = [
            "arn:aws:s3:::${local.chime_app_instance_arn}/protected/$${aws:PrincipalTag/UserUUID}/*"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject"
          ]
          Resource = [
            "arn:aws:s3:::${local.chime_app_instance_arn}/protected/*"
          ]
        }
      ]
    })
  }

  inline_policy {
    name = "chime"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "chime:GetMessagingSessionEndpoint"
          ]
          Effect   = "Allow"
          Resource = ["*"]
        },
        {
          Action = [
            "chime:SendChannelMessage",
            "chime:GetChannelMessage",
            "chime:ListChannelMessages",
            "chime:CreateChannelMembership",
            "chime:ListChannelMemberships",
            "chime:DeleteChannelMembership",
            "chime:CreateChannelModerator",
            "chime:ListChannelModerators",
            "chime:DescribeChannelModerator",
            "chime:RegisterAppInstanceUserEndpoint",
            "chime:ListAppInstanceUserEndpoints",
            "chime:DescribeAppInstanceUserEndpoint",
            "chime:UpdateAppInstanceUserEndpoint",
            "chime:DeregisterAppInstanceUserEndpoint",
            "chime:PutChannelMembershipPreferences",
            "chime:GetChannelMembershipPreferences",
            "chime:CreateChannel",
            "chime:DescribeChannel",
            "chime:ListChannels",
            "chime:UpdateChannel",
            "chime:DeleteChannel",
            "chime:RedactChannelMessage",
            "chime:UpdateChannelMessage",
            "chime:Connect",
            "chime:ListChannelMembershipsForAppInstanceUser",
            "chime:CreateChannelBan",
            "chime:ListChannelBans",
            "chime:DeleteChannelBan"
          ]
          Effect = "Allow"
          Resource = [
            "${local.chime_app_instance_arn}/user/$${aws:PrincipalTag/UserUUID}",
            "${local.chime_app_instance_arn}/channel/*"
          ]
        },
        {
          Action = [
            "chime:ListAppInstanceUsers",
            "chime:DescribeAppInstanceUser"
          ]
          Effect = "Allow"
          Resource = [
            "${local.chime_app_instance_arn}/user/*"
          ]
        }
      ]
    })
  }
  tags = local.tags
}


resource "aws_iam_role" "auth_lambda_anonymous" {
  name        = "${local.service_name}-auth-lambda-anonymous"
  description = "The Role the lambda parameterizes and returns to the user when Anonymous, same as above except no s3 permissions"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.auth_lambda.arn
        }
      },
    ]
  })

  inline_policy {
    name = "cognito-authorized-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "mobileanalytics:PutEvents"
          ]
          Effect   = "Allow"
          Resource = ["*"]
        }
      ]
    })
  }

  inline_policy {
    name = "chime"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "chime:GetMessagingSessionEndpoint"
          ]
          Effect   = "Allow"
          Resource = ["*"]
        },
        {
          Action = [
            "chime:SendChannelMessage",
            "chime:GetChannelMessage",
            "chime:ListChannelMessages",
            "chime:CreateChannelMembership",
            "chime:ListChannelMemberships",
            "chime:DeleteChannelMembership",
            "chime:CreateChannelModerator",
            "chime:ListChannelModerators",
            "chime:DescribeChannelModerator",
            "chime:RegisterAppInstanceUserEndpoint",
            "chime:ListAppInstanceUserEndpoints",
            "chime:DescribeAppInstanceUserEndpoint",
            "chime:UpdateAppInstanceUserEndpoint",
            "chime:DeregisterAppInstanceUserEndpoint",
            "chime:PutChannelMembershipPreferences",
            "chime:GetChannelMembershipPreferences",
            "chime:CreateChannel",
            "chime:DescribeChannel",
            "chime:ListChannels",
            "chime:UpdateChannel",
            "chime:DeleteChannel",
            "chime:RedactChannelMessage",
            "chime:UpdateChannelMessage",
            "chime:Connect",
            "chime:ListChannelMembershipsForAppInstanceUser",
            "chime:CreateChannelBan",
            "chime:ListChannelBans",
            "chime:DeleteChannelBan"
          ]
          Effect = "Allow"
          Resource = [
            "${local.chime_app_instance_arn}/user/$${aws:PrincipalTag/UserUUID}",
            "${local.chime_app_instance_arn}/channel/*",
            local.chime_app_instance_arn
          ]
        },
        {
          Action = [
            "chime:ListAppInstanceUsers",
            "chime:DescribeAppInstanceUser"
          ]
          Effect = "Allow"
          Resource = [
            "${local.chime_app_instance_arn}/user/*"
          ]
        }
      ]
    })
  }
}
