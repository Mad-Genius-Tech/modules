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
    "detail" = {
      "eventType" = ["ERROR"],
      "eventName" = ["SERVICE_DEPLOYMENT_FAILED"]
    }
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


resource "aws_cloudwatch_event_rule" "ecs_task_failure" {
  name        = "${module.ecs_cluster.name}-task-failure"
  description = "ECS ${module.ecs_cluster.name} Task Failure"
  event_pattern = jsonencode({
    "source"      = ["aws.ecs"],
    "detail-type" = ["ECS Task State Change"],
    "detail" = {
      "lastStatus" = ["STOPPED"],
      "stoppedReason" = [{
        "anything-but" = {
          "prefix" = "Scaling activity initiated by"
        }
      }]
    }
  })
}

resource "aws_cloudwatch_event_rule" "ecs_task_stopped" {
  name        = "${module.ecs_cluster.name}-task-stopped"
  description = "${module.ecs_cluster.name} Essential container exited"
  event_pattern = jsonencode({
    "source"      = ["aws.ecs"]
    "detail-type" = ["ECS Task State Change"]
    "detail" = {
      "lastStatus"    = ["STOPPED"]
      "clusterArn"    = [module.ecs_cluster.arn]
      "stoppedReason" = ["Essential container in task exited"]
      "containers" = {
        "exitCode" = [{
          "anything-but" = 0
        }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "ecs_task_stopped" {
  count = var.sns_topic_cloudwatch_alarm_arn != "" ? 1 : 0
  rule  = aws_cloudwatch_event_rule.ecs_task_stopped.name
  arn   = var.sns_topic_cloudwatch_alarm_arn
  input = "{ \"message\": \"Essential container in task exited\", \"account_id\": \"${data.aws_caller_identity.current.account_id}\", \"cluster\": \"${module.ecs_cluster.name}\"}"
}


resource "aws_cloudwatch_event_target" "ecs_task_failure" {
  count = var.sns_topic_cloudwatch_alarm_arn != "" ? 1 : 0
  rule  = aws_cloudwatch_event_rule.ecs_task_failure.name
  arn   = var.sns_topic_cloudwatch_alarm_arn
  input_transformer {
    input_paths = {
      "AZ"              = "$.detail.availabilityZone"
      "ECS_CLUSTER_ARN" = "$.detail.clusterArn"
      "PROBLEM"         = "$.detail-type"
      "REGION"          = "$.region"
      "SERVICE"         = "$.detail.group"
      "STOPPED_REASON"  = "$.detail.stoppedReason"
      "STOPPED_TIME"    = "$.detail.stoppedAt"
      "STOP_CODE"       = "$.detail.stopCode"
      "TASK_ARN"        = "$.detail.taskArn"
    }
    input_template = <<EOT
                "ECS ${module.ecs_cluster.name} TASK FAILURE ALERT"
                "Problem: <PROBLEM>"
                "Region: <REGION>"
                "Availability Zone: <AZ>"
                "ECS Cluster Arn: <ECS_CLUSTER_ARN>"
                "Service Name: <SERVICE>"
                "Task Arn: <TASK_ARN>"
                "Stopped Reason: <STOPPED_REASON>"
                "Stop Code: <STOP_CODE>"
                "Stopped Time: <STOPPED_TIME>"
    EOT
  }
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

resource "aws_cloudwatch_event_target" "ecs_events" {
  rule = aws_cloudwatch_event_rule.ecs_events.name
  arn  = aws_cloudwatch_log_group.ecs_events.arn
}

resource "aws_cloudwatch_log_group" "ecs_events" {
  name              = "/ecs/events/${module.ecs_cluster.name}"
  retention_in_days = 3
  tags              = local.tags
}
