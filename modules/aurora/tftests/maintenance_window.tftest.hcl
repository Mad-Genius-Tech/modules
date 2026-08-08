mock_provider "aws" {
  alias = "contract"

  # Generated mock strings are not valid JSON, and prod's enhanced monitoring
  # feeds one straight into an IAM role. Give the document something the
  # provider will accept so the run reaches the assertions.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  # Same reason: a generated partition lands in a managed policy ARN, which the
  # provider then rejects.
  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }
}

mock_provider "random" {
  alias = "contract"
}

variables {
  org_name     = "example"
  stage_name   = "dev"
  service_name = "central"
  team_name    = "platform"
  vpc_id       = "vpc-00000000000000000"
  subnet_ids   = ["subnet-00000000000000000", "subnet-00000000000000001"]
}

run "an_undeclared_cluster_gets_a_window_and_waits_for_it" {
  command = plan

  providers = {
    aws    = aws.contract
    random = random.contract
  }

  variables {
    aurora = {
      notification = { database_name = "notification" }
    }
  }

  assert {
    condition     = local.aurora_map["notification"].preferred_maintenance_window == "sun:05:00-sun:06:00"
    error_message = "A cluster that declares no window must still get one, or the window is undeclared again on the next module bump."
  }

  assert {
    condition     = local.aurora_map["notification"].apply_immediately == false
    error_message = "Modifications must wait for the maintenance window unless a caller opts in."
  }
}

run "a_caller_can_move_its_own_window" {
  command = plan

  providers = {
    aws    = aws.contract
    random = random.contract
  }

  variables {
    aurora = {
      notification = {
        database_name                = "notification"
        preferred_maintenance_window = "tue:09:00-tue:10:00"
      }
    }
  }

  assert {
    condition     = local.aurora_map["notification"].preferred_maintenance_window == "tue:09:00-tue:10:00"
    error_message = "A declared window must override the module default."
  }
}

run "immediate_application_is_opt_in_per_cluster" {
  command = plan

  providers = {
    aws    = aws.contract
    random = random.contract
  }

  variables {
    aurora = {
      notification = {
        database_name     = "notification"
        apply_immediately = true
      }
      reporting = {
        database_name = "reporting"
        # Spelled out rather than omitted. `coalesce` does not treat `false` as
        # absent, so an explicit opt-out survives the lookup idiom, but that is
        # the kind of thing worth pinning rather than assuming.
        apply_immediately = false
      }
    }
  }

  assert {
    condition     = local.aurora_map["notification"].apply_immediately == true
    error_message = "A cluster that asks for immediate application must get it."
  }

  assert {
    condition     = local.aurora_map["reporting"].apply_immediately == false
    error_message = "An explicit false must not be discarded and fall through to a default."
  }
}

run "prod_stage_defaults_do_not_reintroduce_immediate_applies" {
  command = plan

  providers = {
    aws    = aws.contract
    random = random.contract
  }

  variables {
    stage_name = "prod"
    aurora = {
      notification = { database_name = "notification" }
    }
  }

  assert {
    condition     = local.aurora_map["notification"].apply_immediately == false
    error_message = "Prod must not apply modifications the instant a plan is applied."
  }

  assert {
    condition     = local.aurora_map["notification"].preferred_maintenance_window == "sun:05:00-sun:06:00"
    error_message = "Prod must carry a declared maintenance window."
  }
}
