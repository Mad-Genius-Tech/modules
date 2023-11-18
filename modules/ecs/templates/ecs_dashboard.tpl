{
    "widgets": [
        {
            "height": 6,
            "width": 9,
            "y": 0,
            "x": 0,
            "type": "metric",
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/Usage", "ResourceCount", "Type", "Resource", "Resource", "OnDemand", "Service", "Fargate", "Class", "None", { "region": "${ecs_region}" } ],
                    [ "AWS/Usage", "Spot", "Type", "Resource", "Resource", "OnDemand", { "region": "${ecs_region}" } ]
                ],
                "region": "${ecs_region}",
                "title": "Fargate Resources Allocated",
                "period": 300,
                "annotations": {
                    "horizontal": [
                        {
                            "label": "High consumption",
                            "value": 7
                        }
                    ]
                }
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 0,
            "x": 9,
            "type": "metric",
            "properties": {
                "metrics": [
                    %{ for task_template in ecs_tasks_templates ~}
                    [ "ECS/ContainerInsights", "CpuReserved", "TaskDefinitionFamily", "${task_template}", "ClusterName", "${ecs_cluster_name}", { "region": "${ecs_region}" } ],
                    %{ endfor ~}%{ for task_template in ecs_tasks_templates ~}
                    [ "ECS/ContainerInsights", "CpuUtilized", "TaskDefinitionFamily", "${task_template}", "ClusterName", "${ecs_cluster_name}", { "region": "${ecs_region}" } ]%{if index(ecs_tasks_templates, task_template) != length(ecs_tasks_templates) - 1},%{endif}
                    %{ endfor ~}
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${ecs_region}",
                "period": 300,
                "stat": "Average",
                "yAxis": {
                    "left": {
                        "label": "mCPU"
                    }
                }
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 0,
            "x": 15,
            "type": "metric",
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    %{ for task_template in ecs_tasks_templates ~}
                    [ "ECS/ContainerInsights", "MemoryReserved", "TaskDefinitionFamily", "${task_template}", "ClusterName", "${ecs_cluster_name}", { "region": "${ecs_region}" } ],
                    %{ endfor ~}%{ for task_template in ecs_tasks_templates ~}
                    [ "ECS/ContainerInsights", "MemoryUtilized", "TaskDefinitionFamily", "${task_template}", "ClusterName", "${ecs_cluster_name}", { "region": "${ecs_region}" } ]%{if index(ecs_tasks_templates, task_template) != length(ecs_tasks_templates) - 1},%{endif}
                    %{ endfor ~}
                ],
                "region": "${ecs_region}"
            }
        }
    ]
}
