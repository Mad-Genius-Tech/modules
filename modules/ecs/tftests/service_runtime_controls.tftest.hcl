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
        deployment_circuit_breaker = {
          enable   = true
          rollback = true
        }
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
    condition     = output.ecs_map.hardened.deployment_circuit_breaker.enable && output.ecs_map.hardened.deployment_circuit_breaker.rollback
    error_message = "An explicit deployment circuit breaker must survive normalization."
  }

  assert {
    condition     = length(regexall("deployment_circuit_breaker\\s*=\\s*each\\.value\\.deployment_circuit_breaker", file("${path.module}/main.tf"))) == 2
    error_message = "The deployment circuit breaker override must reach both single- and multi-container ECS services."
  }

  assert {
    condition     = module.ecs_service["hardened"].container_definitions["hardened"].container_definition.readonlyRootFilesystem == true
    error_message = "The readonly_root_filesystem override must reach the generated single-container definition."
  }

  assert {
    condition     = length(regexall("tasks_iam_role_statements\\s*=\\s*length\\(each\\.value\\.tasks_iam_role_statements\\)\\s*>\\s*0\\s*\\?\\s*\\[", file("${path.module}/main.tf"))) == 2
    error_message = "Empty task-policy statements must be passed upstream as null for both single- and multi-container ECS services."
  }

  assert {
    condition     = length(regexall("condition\\s*=\\s*v\\.conditions", file("${path.module}/main.tf"))) == 2 && length(regexall("conditions\\s*=\\s*v\\.conditions", file("${path.module}/main.tf"))) == 0
    error_message = "Task-policy conditions must use the upstream singular condition field for both single- and multi-container ECS services."
  }
}

run "task_definition_retention_is_opt_in" {
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
      default = {
        container_image                = "123456789012.dkr.ecr.us-east-1.amazonaws.com/default:test"
        require_repository_credentials = false
      }
      retained = {
        container_image                = "123456789012.dkr.ecr.us-east-1.amazonaws.com/retained:test"
        require_repository_credentials = false
        skip_destroy                   = true
      }
    }
  }

  assert {
    condition     = output.ecs_map.default.skip_destroy == null
    error_message = "Omitting skip_destroy must preserve the upstream null default."
  }

  assert {
    condition     = output.ecs_map.retained.skip_destroy == true
    error_message = "An explicit skip_destroy=true must survive wrapper normalization."
  }

  assert {
    condition     = length(regexall("skip_destroy\\s*=\\s*each\\.value\\.skip_destroy", file("${path.module}/main.tf"))) == 2
    error_message = "Normalized skip_destroy must be forwarded to both single- and multi-container ECS service paths."
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
