mock_provider "aws" {
  mock_data "aws_s3_bucket" {
    defaults = {
      arn                         = "arn:aws:s3:::example-site"
      bucket                      = "example-site"
      bucket_domain_name          = "example-site.s3.amazonaws.com"
      bucket_regional_domain_name = "example-site.s3.us-west-2.amazonaws.com"
      hosted_zone_id              = "Z3BJ6K6RIION7M"
      region                      = "us-west-2"
      website_domain              = ""
      website_endpoint            = ""
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{}"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/test"
      user_id    = "AIDATEST"
    }
  }
}

mock_provider "aws" {
  alias = "us-east-1"
}

run "privacy_safe_observability_defaults" {
  command = plan

  variables {
    org_name     = "mgb"
    stage_name   = "test"
    service_name = "cloudfront"
    team_name    = "platform"
    tags         = {}

    cloudfront = {
      default = {
        use_acm_cert       = false
        domain_name        = "example.com"
        origin_domain_name = "origin.example.com"
      }
    }
  }

  assert {
    condition     = !local.cloudfront_map.default.enable_logs
    error_message = "CloudFront access logging must remain opt-in for existing consumers."
  }

  assert {
    condition     = !local.cloudfront_map.default.enable_standard_logging_v2
    error_message = "CloudFront standard logging v2 must remain opt-in for existing consumers."
  }

  assert {
    condition     = !local.cloudfront_map.default.logging_include_cookies
    error_message = "Cookie logging must default to disabled."
  }

  assert {
    condition     = local.cloudfront_map.default.logging_retention_days == 30
    error_message = "Access logs must have a bounded default retention."
  }

  assert {
    condition     = !local.cloudfront_map.default.enable_additional_metrics
    error_message = "Paid additional CloudFront metrics must remain opt-in."
  }

  assert {
    condition     = !local.cloudfront_map.default.enable_cloudwatch_alarms
    error_message = "CloudFront error-rate alarms must remain opt-in."
  }
}

run "opted_in_observability_controls" {
  command = plan

  variables {
    org_name     = "mgb"
    stage_name   = "test"
    service_name = "cloudfront"
    team_name    = "platform"
    tags         = {}

    cloudfront = {
      observed = {
        use_acm_cert               = false
        domain_name                = "example.com"
        s3_bucket                  = "example-site"
        enable_standard_logging_v2 = true
        logging_include_cookies    = false
        logging_retention_days     = 14
        enable_additional_metrics  = true
        enable_cloudwatch_alarms   = true
        cloudwatch_alarm_actions   = ["arn:aws:sns:us-east-1:123456789012:edge-alerts"]
        cloudwatch_ok_actions      = ["arn:aws:sns:us-east-1:123456789012:edge-alerts"]
      }
    }
  }

  assert {
    condition     = local.cloudfront_map.observed.enable_standard_logging_v2
    error_message = "An explicit standard logging v2 opt-in must survive normalization."
  }

  assert {
    condition     = !local.cloudfront_map.observed.logging_include_cookies
    error_message = "The privacy-safe cookie setting must survive normalization."
  }

  assert {
    condition     = local.cloudfront_map.observed.logging_retention_days == 14
    error_message = "The configured log retention must survive normalization."
  }

  assert {
    condition     = length(aws_cloudfront_monitoring_subscription.additional_metrics) == 1
    error_message = "An opted-in distribution must create one additional-metrics subscription."
  }

  assert {
    condition     = length(aws_cloudwatch_log_delivery.standard_v2) == 1
    error_message = "An opted-in distribution must create one privacy-filtered standard logging v2 delivery."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.cloudfront_error_rate) == 2
    error_message = "An opted-in distribution must create separate 4xx and 5xx error-rate alarms."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.cloudfront_error_rate["observed-4xxErrorRate"].treat_missing_data == "notBreaching"
    error_message = "Idle CloudFront traffic must not create false alarms."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.cloudfront_error_rate["observed-5xxErrorRate"].dimensions["Region"] == "Global"
    error_message = "CloudFront alarms must use the global metric dimension."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.cloudfront_error_rate["observed-5xxErrorRate"].alarm_actions == toset(["arn:aws:sns:us-east-1:123456789012:edge-alerts"])
    error_message = "The reviewed global-region notification route must reach each alarm."
  }

  assert {
    condition     = length(aws_cloudwatch_log_delivery_source.standard_v2["observed"].name) <= 60 && length(aws_cloudwatch_log_delivery_destination.standard_v2["observed"].name) <= 60
    error_message = "CloudWatch Logs delivery names must remain inside the API length bound."
  }

  assert {
    condition = alltrue([
      for forbidden in ["c-ip", "cs-uri-query", "cs(Cookie)", "cs(Referer)", "cs(User-Agent)", "x-forwarded-for"] :
      !contains(local.standard_logging_v2_record_fields, forbidden)
    ])
    error_message = "The standard logging v2 field set must exclude IP, query, cookie, referer, user-agent, and forwarded-for data."
  }

  assert {
    condition     = length(regexall("include_cookies\\s*=\\s*each\\.value\\.logging_include_cookies", file("${path.module}/main.tf"))) == 1
    error_message = "The normalized cookie setting must reach the CloudFront logging configuration."
  }

  assert {
    condition     = length(regexall("days\\s*=\\s*each\\.value\\.logging_retention_days", file("${path.module}/main.tf"))) == 1
    error_message = "The normalized retention setting must reach the log-bucket lifecycle."
  }
}

run "reject_unbounded_log_retention" {
  command = plan

  variables {
    org_name     = "mgb"
    stage_name   = "test"
    service_name = "cloudfront"
    team_name    = "platform"
    tags         = {}

    cloudfront = {
      invalid = {
        use_acm_cert           = false
        domain_name            = "example.com"
        origin_domain_name     = "origin.example.com"
        enable_logs            = true
        logging_retention_days = 0
      }
    }
  }

  expect_failures = [var.cloudfront]
}

run "reject_alarm_without_route" {
  command = plan

  variables {
    org_name     = "mgb"
    stage_name   = "test"
    service_name = "cloudfront"
    team_name    = "platform"
    tags         = {}

    cloudfront = {
      invalid = {
        use_acm_cert             = false
        domain_name              = "example.com"
        origin_domain_name       = "origin.example.com"
        enable_cloudwatch_alarms = true
      }
    }
  }

  expect_failures = [aws_cloudwatch_metric_alarm.cloudfront_error_rate]
}

run "module_topic_backs_alarms_without_explicit_actions" {
  command = plan

  variables {
    org_name     = "mgb"
    stage_name   = "test"
    service_name = "cloudfront"
    team_name    = "platform"
    tags         = {}

    alarm_topic_email_subscriptions = ["edge-alerts@example.com"]

    cloudfront = {
      routed = {
        use_acm_cert             = false
        domain_name              = "example.com"
        origin_domain_name       = "origin.example.com"
        enable_cloudwatch_alarms = true
      }
    }
  }

  assert {
    condition     = length(aws_sns_topic.cloudfront_alarm) == 1 && length(aws_sns_topic_subscription.cloudfront_alarm_email) == 1
    error_message = "A module-owned us-east-1 topic and its email subscription must back alarms that set no explicit actions."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.cloudfront_error_rate) == 2
    error_message = "Alarms without explicit actions must still be created when the module-owned topic exists."
  }
}
