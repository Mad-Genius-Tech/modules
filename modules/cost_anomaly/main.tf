

resource "aws_ce_anomaly_monitor" "service_monitor" {
  count             = var.sns_topic_arn != "" ? 1 : 0
  name              = "AWSServiceMonitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
  tags              = local.tags
}

resource "aws_ce_anomaly_subscription" "subscription" {
  count     = var.sns_topic_arn != "" ? 1 : 0
  name      = "AnomalySubscription"
  frequency = "IMMEDIATE"

  monitor_arn_list = [
    aws_ce_anomaly_monitor.service_monitor[0].arn,
  ]

  subscriber {
    type    = "SNS"
    address = var.sns_topic_arn
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
