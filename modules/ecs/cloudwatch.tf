resource "aws_cloudwatch_metric_alarm" "ecs_high_cpu_reservation" {
  count               = var.high_reservation_alert && var.sns_topic_cloudwatch_alarm_arn != "" ? 1 : 0
  alarm_name          = "${module.ecs_cluster.name}-high-cpu-reservation"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  period              = "60"
  evaluation_periods  = "2"
  datapoints_to_alarm = 2
  statistic           = "Average"
  threshold           = "75"
  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"
  dimensions = {
    ClusterName = module.ecs_cluster.name
  }
  actions_enabled           = true
  insufficient_data_actions = []
  ok_actions                = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"
  ]
}

resource "aws_cloudwatch_metric_alarm" "ecs_low_cpu_reservation" {
  count               = var.low_reservation_alert && var.sns_topic_cloudwatch_alarm_arn != "" ? 1 : 0
  alarm_name          = "${module.ecs_cluster.name}-low-cpu-reservation"
  comparison_operator = "LessThanThreshold"
  period              = "300"
  evaluation_periods  = "1"
  datapoints_to_alarm = 1
  statistic           = "Average"
  threshold           = "40"
  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"
  dimensions = {
    ClusterName = module.ecs_cluster.name
  }
  actions_enabled           = true
  insufficient_data_actions = []
  ok_actions                = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"
  ]
}

resource "aws_cloudwatch_metric_alarm" "ecs_high_mem_reservation" {
  count               = var.high_reservation_alert && var.sns_topic_cloudwatch_alarm_arn != "" ? 1 : 0
  alarm_name          = "${module.ecs_cluster.name}-high-mem-reservation"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  period              = "60"
  evaluation_periods  = "2"
  datapoints_to_alarm = 2
  statistic           = "Average"
  threshold           = "75"
  metric_name         = "MemoryReservation"
  namespace           = "AWS/ECS"
  dimensions = {
    ClusterName = module.ecs_cluster.name
  }
  actions_enabled           = true
  insufficient_data_actions = []
  ok_actions                = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"
  ]
}

resource "aws_cloudwatch_metric_alarm" "ecs_low_mem_reservation" {
  count               = var.low_reservation_alert && var.sns_topic_cloudwatch_alarm_arn != "" ? 1 : 0
  alarm_name          = "${module.ecs_cluster.name}-low-mem-reservation"
  comparison_operator = "LessThanThreshold"
  period              = "300"
  evaluation_periods  = "1"
  datapoints_to_alarm = 1
  statistic           = "Average"
  threshold           = "40"
  metric_name         = "MemoryReservation"
  namespace           = "AWS/ECS"
  dimensions = {
    ClusterName = module.ecs_cluster.name
  }
  actions_enabled           = true
  insufficient_data_actions = []
  ok_actions                = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"
  ]
}

# Running-task liveness from the free AWS/ECS namespace: every running task
# publishes one CPUUtilization sample per minute per service, so SampleCount
# over a 60 s period equals the running task count. This no longer depends
# on ECS/ContainerInsights (billed as ~30 custom metrics per service), so the
# alarm exists whenever an SNS topic is configured, with insights on or off.
resource "aws_cloudwatch_metric_alarm" "ecs_service_running_tasks_below_desired" {
  # Single for-expression (no conditional) so Terraform <= 1.8 does not
  # reject the heterogeneous object type against the empty-map fallback.
  for_each = {
    for k, v in local.ecs_map : k => v
    if var.sns_topic_cloudwatch_alarm_arn != "" && v.create && v.type == "service"
  }

  alarm_name          = "${each.value.identifier}-running-tasks-below-desired"
  alarm_description   = "ECS service ${each.value.identifier} has fewer running tasks than desired"
  comparison_operator = "LessThanThreshold"
  threshold           = each.value.desired_count
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  statistic           = "SampleCount"
  period              = 60
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  treat_missing_data  = each.value.desired_count == 0 ? "notBreaching" : "breaching"
  dimensions = {
    ClusterName = module.ecs_cluster.name
    ServiceName = each.value.identifier
  }
  actions_enabled           = true
  insufficient_data_actions = []
  ok_actions = [
    var.sns_topic_cloudwatch_alarm_arn
  ]
  alarm_actions = [
    var.sns_topic_cloudwatch_alarm_arn
  ]
}

resource "aws_cloudwatch_dashboard" "ecs" {
  dashboard_name = module.ecs_cluster.name
  dashboard_body = templatefile("${path.module}/templates/ecs_dashboard.tpl",
    {
      ecs_cluster_name    = module.ecs_cluster.name
      ecs_region          = data.aws_region.current.name
      ecs_tasks_templates = [for v in values(local.ecs_map) : v.identifier if v.create]
    }
  )
}

resource "aws_cloudwatch_event_rule" "ecs_deployment_failure" {
  name        = "${module.ecs_cluster.name}-deployment-failure"
  description = "ECS ${module.ecs_cluster.name} Deployment Failure"
  event_pattern = jsonencode({
    "source"      = ["aws.ecs"],
    "detail-type" = ["ECS Deployment State Change"],
    "resources"   = [{ "prefix" = "${replace(module.ecs_cluster.arn, ":cluster/", ":service/")}/" }],
    "detail" = {
      "eventType" = ["ERROR"],
      "eventName" = ["SERVICE_DEPLOYMENT_FAILED"]
    }
  })
}

resource "aws_cloudwatch_event_target" "ecs_deployment_failure" {
  count      = var.sns_topic_cloudwatch_alarm_arn != "" ? 1 : 0
  rule       = aws_cloudwatch_event_rule.ecs_deployment_failure.name
  arn        = var.sns_topic_cloudwatch_alarm_arn
  role_arn   = aws_iam_role.ecs_alert_publisher[0].arn
  depends_on = [aws_iam_role_policy.ecs_alert_publisher]
}

# EventBridge may publish deployment failures only; task-failure alarms use CloudWatch.
resource "aws_iam_role" "ecs_alert_publisher" {
  count = var.sns_topic_cloudwatch_alarm_arn != "" ? 1 : 0
  name  = "${module.ecs_cluster.name}-alert-publisher"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
        ArnEquals = {
          "aws:SourceArn" = [
            aws_cloudwatch_event_rule.ecs_deployment_failure.arn,
          ]
        }
      }
    }]
  })
  tags = local.tags
}

resource "aws_iam_role_policy" "ecs_alert_publisher" {
  count = var.sns_topic_cloudwatch_alarm_arn != "" ? 1 : 0
  name  = "PublishECSAlerts"
  role  = aws_iam_role.ecs_alert_publisher[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sns:Publish"
      Resource = var.sns_topic_cloudwatch_alarm_arn
    }]
  })
}


# Sample Event:
# {
#   "version": "0",
#   "id": "af0835c5-401a-44a8-7d94-99effc34dc29",
#   "detail-type": "ECS Deployment State Change",
#   "source": "aws.ecs",
#   "account": "xxxxxxxxxxxx",
#   "time": "2022-07-20T11:09:36Z",
#   "region": "eu-central-1",
#   "resources": [
#     "arn:aws:ecs:eu-central-1:xxxxxxxxxxxx:service/project-staging/web"
#   ],
#   "detail": {
#     "eventType": "INFO",
#     "eventName": "SERVICE_DEPLOYMENT_COMPLETED",
#     "deploymentId": "ecs-svc/4231880795355584839",
#     "updatedAt": "2022-07-20T11:08:21.049Z",
#     "reason": "ECS deployment ecs-svc/4231880795355584839 completed."
#   }
# }
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_cwe_events.html#ecs_service_deployment_events


# Task failures: alert on the first failure, then group repeats.
#
# The rule/alarm pair replaces the former ecs_task_failure and ecs_task_stopped
# EventBridge -> SNS targets. Those published one SNS message per stopped task,
# and every non-zero essential-container exit matched BOTH rules, so one crash
# produced two publishes (and each publish fanned out to every subscription).
#
# Each rule below has no target. Consumers must observe RuleName-scoped
# TriggeredRules datapoints before retiring their direct event route. Metrics
# are best effort; an OK state means a quiet observed failure window, not
# service recovery. Independent running-task alarms remain enabled.
locals {
  ecs_task_failure_services = {
    for k, v in local.ecs_map : k => v
    if var.sns_topic_cloudwatch_alarm_arn != "" && v.create && v.type == "service"
  }

  # Deployment replacement and scale-in stops are not failures. Fargate Spot
  # interruptions (stopCode SpotInterruption) are expected capacity reclaims:
  # they never page here. If the replacement task does not come back, the
  # stateful ecs_service_running_tasks_below_desired alarm (running < desired
  # for 2 x 60s) pages instead.
  ecs_task_failure_stopped = {
    clusterArn = [module.ecs_cluster.arn]
    lastStatus = ["STOPPED"]
    stoppedReason = [{
      "anything-but" = {
        "prefix" = "Scaling activity initiated by"
      }
    }]
  }
}

# Any stop of a long-running service task other than scale-in/deployment
# replacement, scheduled host maintenance or a Spot interruption is a failure, including a container that
# exits 0, ELB health-check replacement and startup failures.
resource "aws_cloudwatch_event_rule" "ecs_service_task_failure" {
  for_each    = local.ecs_task_failure_services
  name        = "${each.value.identifier}-task-failure"
  description = "ECS ${each.value.identifier} stopped task (grouped by alarm)"
  event_pattern = jsonencode({
    "source"      = ["aws.ecs"]
    "detail-type" = ["ECS Task State Change"]
    "detail" = merge(local.ecs_task_failure_stopped, {
      # Scheduled ECS host maintenance is an expected replacement. Keep
      # unexpected exits and health-check stops, and let running-below-desired
      # alarms catch a replacement that fails to return.
      "stoppedReason" = [{
        "anything-but" = {
          "prefix" = [
            "Scaling activity initiated by",
            "Service ${each.value.identifier}: ECS is performing maintenance on the underlying infrastructure hosting the task",
          ]
        }
      }]
      "group"    = ["service:${each.value.identifier}"]
      "stopCode" = [{ "anything-but" = ["SpotInterruption"] }]
    })
  })
  tags = local.tags
}

# Standalone and scheduled one-shot tasks: a command that exits 0 is success.
# Alert only on a non-zero/missing exit code or a non-exit stop (for example
# image pull, secret resolution, capacity or startup failures).
resource "aws_cloudwatch_event_rule" "ecs_standalone_task_failure" {
  count       = var.sns_topic_cloudwatch_alarm_arn != "" ? 1 : 0
  name        = "${module.ecs_cluster.name}-standalone-task-failure"
  description = "ECS ${module.ecs_cluster.name} failed standalone/scheduled task (grouped by alarm)"
  event_pattern = jsonencode({
    "source"      = ["aws.ecs"]
    "detail-type" = ["ECS Task State Change"]
    "detail" = merge(local.ecs_task_failure_stopped, {
      "group" = [{
        "anything-but" = {
          "prefix" = "service:"
        }
      }]
      # Keep stopCode entirely inside each branch: EventBridge does not
      # combine a repeated field outside $or with that field inside a branch.
      "$or" = [
        { stopCode = [{ "anything-but" = ["EssentialContainerExited", "SpotInterruption"] }] },
        {
          stopCode   = [{ "anything-but" = ["SpotInterruption"] }]
          containers = { exitCode = [{ "anything-but" = 0 }, { exists = false }] }
        },
      ]
    })
  })
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_service_task_failure" {
  for_each            = local.ecs_task_failure_services
  alarm_name          = "${each.value.identifier}-task-failure"
  alarm_description   = "ECS service ${each.value.identifier} stopped a task outside scale-in, deployment replacement, scheduled ECS host maintenance or Spot interruption (capacity loss pages via running-below-desired). Failures are grouped over ${var.task_failure_alarm_window_minutes} evaluation periods of 60 seconds. OK means no recent observed matching failures, not verified service recovery. Task detail: CloudWatch Logs /ecs/events/${module.ecs_cluster.name}, filter detail.group = service:${each.value.identifier}."
  namespace           = "AWS/Events"
  metric_name         = "TriggeredRules"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = var.task_failure_alarm_window_minutes
  datapoints_to_alarm = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  dimensions = {
    RuleName = aws_cloudwatch_event_rule.ecs_service_task_failure[each.key].name
  }
  actions_enabled           = true
  insufficient_data_actions = []
  alarm_actions             = [var.sns_topic_cloudwatch_alarm_arn]
  ok_actions                = var.task_failure_ok_notifications ? [var.sns_topic_cloudwatch_alarm_arn] : []
  tags                      = local.tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_standalone_task_failure" {
  count               = var.sns_topic_cloudwatch_alarm_arn != "" ? 1 : 0
  alarm_name          = "${module.ecs_cluster.name}-standalone-task-failure"
  alarm_description   = "A standalone or scheduled ECS task in ${module.ecs_cluster.name} failed (non-zero exit or failed start). Successful exit-0 runs and Spot interruptions never match. Failures are grouped over ${var.task_failure_alarm_window_minutes} evaluation periods of 60 seconds. OK means no recent observed matching failures, not successful job completion. Task detail: CloudWatch Logs /ecs/events/${module.ecs_cluster.name}."
  namespace           = "AWS/Events"
  metric_name         = "TriggeredRules"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = var.task_failure_alarm_window_minutes
  datapoints_to_alarm = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  dimensions = {
    RuleName = aws_cloudwatch_event_rule.ecs_standalone_task_failure[0].name
  }
  actions_enabled           = true
  insufficient_data_actions = []
  alarm_actions             = [var.sns_topic_cloudwatch_alarm_arn]
  ok_actions                = var.task_failure_ok_notifications ? [var.sns_topic_cloudwatch_alarm_arn] : []
  tags                      = local.tags
}


resource "aws_cloudwatch_event_rule" "ecs_events" {
  name        = "${module.ecs_cluster.name}-events"
  description = "Capture ecs service events from ${module.ecs_cluster.name}"
  event_pattern = jsonencode({
    "source"      = ["aws.ecs"],
    "detail-type" = ["ECS Task State Change", "ECS Container Instance State Change"],
    "detail" = {
      "clusterArn" = [module.ecs_cluster.arn]
    }
  })
}

# CloudWatch Logs targets use a resource policy, not an EventBridge role.
# Attach it to this group to avoid consuming the account policy quota.
# Grant delivery only to this cluster's existing event-log group streams.
# https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-use-resource-based.html
resource "aws_cloudwatch_log_resource_policy" "ecs_events" {
  resource_arn = trimsuffix(aws_cloudwatch_log_group.ecs_events.arn, ":*")
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "EventBridgeECSLogs"
      Effect    = "Allow"
      Principal = { Service = ["events.amazonaws.com", "delivery.logs.amazonaws.com"] }
      Action    = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource  = "${trimsuffix(aws_cloudwatch_log_group.ecs_events.arn, ":*")}:*"
    }]
  })
}

resource "aws_cloudwatch_event_target" "ecs_events" {
  rule       = aws_cloudwatch_event_rule.ecs_events.name
  arn        = aws_cloudwatch_log_group.ecs_events.arn
  depends_on = [aws_cloudwatch_log_resource_policy.ecs_events]
}

resource "aws_cloudwatch_log_group" "ecs_events" {
  name              = "/ecs/events/${module.ecs_cluster.name}"
  retention_in_days = 3
  tags              = local.tags
}
