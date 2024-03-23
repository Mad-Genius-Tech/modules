
locals {
  overall_budget_map = {
    for k, v in var.overall_budget : k => {
      time_unit                  = upper(k)
      limit_amount               = coalesce(v.limit_amount, 0)
      threshold_percentage       = coalesce(v.threshold_percentage, 50)
      include_credit             = coalesce(v.include_credit, true)
      include_discount           = coalesce(v.include_credit, true)
      include_other_subscription = coalesce(v.include_credit, true)
      include_recurring          = coalesce(v.include_credit, true)
      include_refund             = coalesce(v.include_credit, true)
      include_subscription       = coalesce(v.include_credit, true)
      include_support            = coalesce(v.include_credit, true)
      include_tax                = coalesce(v.include_credit, true)
      include_upfront            = coalesce(v.include_credit, true)
      use_amortized              = coalesce(v.include_credit, false)
      use_blended                = coalesce(v.include_credit, false)
    }
  }

  cost_anomaly = {
    raise_amount_absolute   = coalesce(var.cost_anomaly.raise_amount_absolute, 50)
    raise_amount_percentage = coalesce(var.cost_anomaly.raise_amount_percentage, 10)
  }
}

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
        values        = [local.cost_anomaly.raise_amount_percentage]
        match_options = ["GREATER_THAN_OR_EQUAL"]
      }
    }
    or {
      dimension {
        key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
        values        = [local.cost_anomaly.raise_amount_absolute]
        match_options = ["GREATER_THAN_OR_EQUAL"]
      }
    }
  }
  tags = local.tags
}

resource "aws_budgets_budget" "monthly_overall_budget" {
  for_each          = { for k, v in local.overall_budget_map : k => v if upper(k) == "MONTHLY" && v.limit_amount > 0}
  name              = "overall-monthly-budget-cost-alert"
  budget_type       = "COST"
  limit_amount      = each.value.limit_amount
  limit_unit        = "USD"
  time_period_start = "2021-01-01_00:00"
  time_unit         = "MONTHLY"

  cost_types {
    # List of available cost types: 
    # https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_budgets_CostTypes.html
    include_credit             = each.value.include_credit
    include_discount           = each.value.include_discount
    include_other_subscription = each.value.include_other_subscription
    include_recurring          = each.value.include_recurring
    include_refund             = each.value.include_refund
    include_subscription       = each.value.include_subscription
    include_support            = each.value.include_support
    include_tax                = each.value.include_tax
    include_upfront            = each.value.include_upfront
    use_amortized              = each.value.use_amortized
    use_blended                = each.value.use_blended
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = each.value.threshold_percentage
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_sns_topic_arns  = var.sns_topic_arn != "" ? [var.sns_topic_arn] : null
    subscriber_email_addresses = var.notification_email != "" ? [var.notification_email] : null
  }

}


resource "aws_budgets_budget" "daily_overall_budget" {
  for_each          = { for k, v in local.overall_budget_map : k => v if upper(k) == "DAILY" && v.limit_amount > 0}
  name              = "overall-daily-budget-cost-alert"
  budget_type       = "COST"
  limit_amount      = each.value.limit_amount
  limit_unit        = "USD"
  time_period_start = "2021-01-01_00:00"
  time_unit         = "DAILY"

  cost_types {
    # List of available cost types: 
    # https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_budgets_CostTypes.html
    include_credit             = each.value.include_credit
    include_discount           = each.value.include_discount
    include_other_subscription = each.value.include_other_subscription
    include_recurring          = each.value.include_recurring
    include_refund             = each.value.include_refund
    include_subscription       = each.value.include_subscription
    include_support            = each.value.include_support
    include_tax                = each.value.include_tax
    include_upfront            = each.value.include_upfront
    use_amortized              = each.value.use_amortized
    use_blended                = each.value.use_blended
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = each.value.threshold_percentage
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_topic_arns  = var.sns_topic_arn != "" ? [var.sns_topic_arn] : null
    subscriber_email_addresses = var.notification_email != "" ? [var.notification_email] : null
  }

}


locals {
  service_filter = {
    "ec2"         = "Amazon Elastic Compute Cloud - Compute",
    "redshift"    = "Amazon Redshift",
    "rds"         = "Amazon Relational Database Service",
    "elasticache" = "Amazon ElastiCache",
    "opensearch"  = "Amazon OpenSearch Service",
  }

  services_budget_map = {
    for k, v in var.services_budget : k => {
      time_unit            = coalesce(v.time_unit, "MONTHLY")
      limit_amount         = coalesce(v.limit_amount, 100)
      threshold_percentage = coalesce(v.threshold_percentage, 50)
    }
  }
}

resource "aws_budgets_budget" "per_service_budget" {
  for_each          = local.services_budget_map
  name              = "${lower(each.key)}-budget-cost-${each.value.time_unit}-alert"
  budget_type       = "COST"
  limit_amount      = each.value.limit_amount
  limit_unit        = "USD"
  time_period_start = "2021-01-01_00:00"
  time_unit         = each.value.time_unit

  cost_filter {
    name = "Service"
    values = [
      lookup(local.service_filter, each.key)
    ]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = each.value.threshold_percentage
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_sns_topic_arns  = var.sns_topic_arn != "" ? [var.sns_topic_arn] : null
    subscriber_email_addresses = var.notification_email != "" ? [var.notification_email] : null
  }
}