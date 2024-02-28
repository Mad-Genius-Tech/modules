resource "aws_ce_anomaly_monitor" "service_monitor" {
  name              = "AWSServiceMonitor"
  monitor_type      = var.cost_category == null ? "DIMENSIONAL" : "CUSTOM"
  monitor_dimension = var.cost_category == null ? "SERVICE" : null

  monitor_specification = var.cost_category == null ? null : jsonencode(
    {
      And = null
      CostCategories = {
        Key          = var.cost_category.name
        Values       = [var.cost_category.value]
        MatchOptions = null
      }
      Dimensions = null
      Not        = null
      Or         = null
      Tags       = null
    }
  )
  tags = local.tags
}

resource "aws_ce_anomaly_subscription" "subscription" {
  count     = var.sns_topic_arn != "" ? 1 : 0
  name      = "AnomalySubscription"
  frequency = "IMMEDIATE"

  monitor_arn_list = [
    aws_ce_anomaly_monitor.service_monitor.arn,
  ]

  subscriber {
    type    = "SNS"
    address = var.sns_topic_arn
  }

  dynamic "subscriber" {
    for_each = var.notification_email != "" ? [var.notification_email] : []

    content {
      type    = "EMAIL"
      address = var.notification_email
    }
  }

  dynamic "subscriber" {
    for_each = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

    content {
      type    = "SNS"
      address = var.sns_topic_arn
    }
  }

  threshold_expression {
    or {
      dimension {
        key           = "ANOMALY_TOTAL_IMPACT_PERCENTAGE"
        values        = [var.raise_amount_percentage]
        match_options = ["GREATER_THAN_OR_EQUAL"]
      }
    }
    or {
      dimension {
        key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
        values        = [var.raise_amount_absolute]
        match_options = ["GREATER_THAN_OR_EQUAL"]
      }
    }
  }
  tags = local.tags
}
