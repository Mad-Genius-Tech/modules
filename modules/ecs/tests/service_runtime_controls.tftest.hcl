mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/test"
      user_id    = "AIDATEST"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{}"
    }
  }

  mock_data "aws_ecs_service" {
    defaults = {
      task_definition = "arn:aws:ecs:us-east-1:123456789012:task-definition/mgb-test-rt-auth:7"
      network_configuration = [{
        assign_public_ip = false
        security_groups  = ["sg-auth"]
        subnets          = ["subnet-private"]
      }]
    }
  }

  mock_data "aws_ecs_task_definition" {
    defaults = {
      arn                = "arn:aws:ecs:us-east-1:123456789012:task-definition/mgb-test-rt-auth:7"
      execution_role_arn = "arn:aws:iam::123456789012:role/auth-execution"
      task_role_arn      = "arn:aws:iam::123456789012:role/auth-task"
    }
  }
}

run "runtime_control_defaults" {
  command = plan

  variables {
    org_name            = "mgb"
    stage_name          = "test"
    service_name        = "rt"
    team_name           = "platform"
    tags                = {}
    private_subnets     = ["subnet-private"]
    public_subnets      = ["subnet-public"]
    ingress_cidr_blocks = ["10.0.0.0/16"]
    vpc_id              = "vpc-test"
    vpc_cidr            = "10.0.0.0/16"
    create_internal_alb = false

    ecs_services = {
      defaults = {
        container_image                = "123456789012.dkr.ecr.us-east-1.amazonaws.com/defaults:test"
        require_repository_credentials = false
      }
    }
  }

  assert {
    condition     = output.ecs_map.defaults.enable_execute_command
    error_message = "ECS Exec must remain enabled by default for backward compatibility."
  }

  assert {
    condition     = !output.ecs_map.defaults.readonly_root_filesystem
    error_message = "The single-container root filesystem must remain writable by default for backward compatibility."
  }

  assert {
    condition     = module.ecs_service["defaults"].container_definitions["defaults"].container_definition.readonlyRootFilesystem == false
    error_message = "The default readonly_root_filesystem value must reach the generated single-container definition."
  }

  assert {
    condition     = length(regexall("enable_execute_command\\s*=\\s*each\\.value\\.enable_execute_command", file("${path.module}/main.tf"))) == 2
    error_message = "Normalized enable_execute_command must be forwarded to both single- and multi-container ECS services."
  }

  assert {
    condition     = length(regexall("depends_on\\s*=\\s*\\[\\s*module\\.ecs_service,\\s*module\\.ecs_service_multiples\\s*\\]", file("${path.module}/scheduled_tasks.tf"))) == 0
    error_message = "Scheduled targets must rely on exact resource references instead of a module-wide ECS service dependency."
  }

  assert {
    condition     = length(regexall("depends_on\\s*=\\s*\\[\\s*aws_iam_role_policy\\.scheduler_run_task\\s*\\]", file("${path.module}/scheduled_tasks.tf"))) == 1
    error_message = "Scheduled targets must wait for their exact scheduler IAM policy."
  }

  assert {
    condition     = length(regexall("module\\.ecs_service", file("${path.module}/scheduled_tasks.tf"))) == 0
    error_message = "Scheduled-task resources must not depend on ECS service module instances."
  }
}

run "runtime_control_overrides" {
  command = plan

  variables {
    org_name            = "mgb"
    stage_name          = "test"
    service_name        = "rt"
    team_name           = "platform"
    tags                = {}
    private_subnets     = ["subnet-private"]
    public_subnets      = ["subnet-public"]
    ingress_cidr_blocks = ["10.0.0.0/16"]
    vpc_id              = "vpc-test"
    vpc_cidr            = "10.0.0.0/16"
    create_internal_alb = false

    ecs_services = {
      hardened = {
        container_image                = "123456789012.dkr.ecr.us-east-1.amazonaws.com/hardened:test"
        require_repository_credentials = false
        enable_execute_command         = false
        readonly_root_filesystem       = true
      }
    }
  }

  assert {
    condition     = !output.ecs_map.hardened.enable_execute_command
    error_message = "An explicit enable_execute_command=false override must survive normalization."
  }

  assert {
    condition     = output.ecs_map.hardened.readonly_root_filesystem
    error_message = "An explicit readonly_root_filesystem=true override must survive normalization."
  }

  assert {
    condition     = module.ecs_service["hardened"].container_definitions["hardened"].container_definition.readonlyRootFilesystem == true
    error_message = "The readonly_root_filesystem override must reach the generated single-container definition."
  }

  assert {
    condition     = length(regexall("tasks_iam_role_statements\\s*=\\s*length\\(each\\.value\\.tasks_iam_role_statements\\)\\s*>\\s*0\\s*\\?\\s*\\[", file("${path.module}/main.tf"))) == 2
    error_message = "Empty task-policy statements must be passed upstream as null for both single- and multi-container ECS services."
  }
}

run "reject_single_container_control_for_multi_container_service" {
  command = plan

  variables {
    org_name            = "mgb"
    stage_name          = "test"
    service_name        = "rt"
    team_name           = "platform"
    tags                = {}
    private_subnets     = ["subnet-private"]
    public_subnets      = ["subnet-public"]
    ingress_cidr_blocks = ["10.0.0.0/16"]
    vpc_id              = "vpc-test"
    vpc_cidr            = "10.0.0.0/16"
    create_internal_alb = false

    ecs_services = {
      multi = {
        container_image          = "123456789012.dkr.ecr.us-east-1.amazonaws.com/multi:test"
        multiple_containers      = true
        readonly_root_filesystem = true
        subnet_ids               = ["subnet-private"]
        container_definitions = {
          app = {
            essential = true
            cpu       = 256
            memory    = 512
            image     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/multi:test"
          }
        }
      }
    }
  }

  expect_failures = [var.ecs_services]
}
