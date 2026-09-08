mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { name = "us-east-1" }
  }
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/test"
      user_id    = "AIDATEST"
    }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{}" }
  }
}

variables {
  org_name            = "mgb"
  stage_name          = "test"
  service_name        = "ingress"
  team_name           = "platform"
  private_subnets     = ["subnet-private"]
  public_subnets      = ["subnet-public"]
  ingress_cidr_blocks = ["10.0.0.0/16"]
  vpc_id              = "vpc-test"
  vpc_cidr            = "10.0.0.0/16"
  create_internal_alb = false
}

# These plans exercise the public input contract and normalized output without
# provisioning a service or depending on unrelated container serialization.
run "default_ingress_is_unchanged" {
  command = plan
  variables {
    ecs_services = {
      gateway = { create = false, container_port = 8000 }
    }
  }
  assert {
    condition     = output.ecs_map.gateway.security_group_ingress_rules_resolved.ingress_8000.cidr_ipv4 == "10.0.0.0/16"
    error_message = "Omitting overrides must preserve the existing VPC ingress rule."
  }
}

run "legacy_cidr_overrides_are_compatible" {
  command = plan
  variables {
    ecs_services = {
      gateway = {
        create         = false
        container_port = 8000
        security_group_rules = {
          ingress_8000 = { from_port = 8000, to_port = 8000, cidr_ipv4 = "10.0.32.0/19" }
          admin        = { from_port = 8001, to_port = 8002, cidr_ipv4 = "10.0.32.0/19" }
        }
      }
    }
  }
  assert {
    condition = (
      length(output.ecs_map.gateway.security_group_ingress_rules_resolved) == 2 &&
      output.ecs_map.gateway.security_group_ingress_rules_resolved.ingress_8000.cidr_ipv4 == "10.0.32.0/19" &&
      output.ecs_map.gateway.security_group_ingress_rules_resolved.admin.from_port == 8001
    )
    error_message = "Existing CIDR overrides must replace the default ingress key and preserve unrelated rules."
  }
}

run "security_group_reference_survives_normalization" {
  command = plan
  variables {
    ecs_services = {
      gateway = {
        create         = false
        container_port = 8000
        security_group_rules = {
          ingress_8000 = { from_port = 8000, to_port = 8000, cidr_ipv4 = "10.0.32.0/19" }
          public_alb = {
            from_port                    = 8000
            to_port                      = 8000
            referenced_security_group_id = "sg-0123456789abcdef0"
          }
        }
      }
    }
  }
  assert {
    condition = (
      output.ecs_map.gateway.security_group_ingress_rules_resolved.public_alb.referenced_security_group_id == "sg-0123456789abcdef0" &&
      output.ecs_map.gateway.security_group_ingress_rules_resolved.public_alb.cidr_ipv4 == null &&
      output.ecs_map.gateway.security_group_ingress_rules_resolved.ingress_8000.cidr_ipv4 == "10.0.32.0/19"
    )
    error_message = "An SG-only rule must remain SG-only while the caller narrows the default VPC ingress."
  }
}

run "security_group_can_replace_default_ingress" {
  command = plan
  variables {
    ecs_services = {
      gateway = {
        create         = false
        container_port = 8000
        security_group_rules = {
          ingress_8000 = {
            from_port                    = 8000
            to_port                      = 8000
            cidr_ipv4                    = null
            referenced_security_group_id = "sg-0123456789abcdef0"
          }
        }
      }
    }
  }
  assert {
    condition = (
      length(output.ecs_map.gateway.security_group_ingress_rules_resolved) == 1 &&
      output.ecs_map.gateway.security_group_ingress_rules_resolved.ingress_8000.referenced_security_group_id == "sg-0123456789abcdef0" &&
      output.ecs_map.gateway.security_group_ingress_rules_resolved.ingress_8000.cidr_ipv4 == null
    )
    error_message = "Replacing the default rule with an SG source must not retain its VPC CIDR."
  }
}

run "reject_both_sources" {
  command = plan
  variables {
    ecs_services = {
      gateway = {
        create = false
        security_group_rules = {
          ingress = {
            from_port                    = 8000
            to_port                      = 8000
            cidr_ipv4                    = "10.0.0.0/16"
            referenced_security_group_id = "sg-0123456789abcdef0"
          }
        }
      }
    }
  }
  expect_failures = [var.ecs_services]
}

run "reject_missing_source" {
  command = plan
  variables {
    ecs_services = {
      gateway = {
        create = false
        security_group_rules = {
          ingress = {
            from_port = 8000
            to_port   = 8000
          }
        }
      }
    }
  }
  expect_failures = [var.ecs_services]
}

run "reject_empty_cidr" {
  command = plan
  variables {
    ecs_services = {
      gateway = {
        create = false
        security_group_rules = {
          ingress = {
            from_port = 8000
            to_port   = 8000
            cidr_ipv4 = ""
          }
        }
      }
    }
  }
  expect_failures = [var.ecs_services]
}

run "reject_whitespace_cidr" {
  command = plan
  variables {
    ecs_services = {
      gateway = {
        create = false
        security_group_rules = {
          ingress = {
            from_port = 8000
            to_port   = 8000
            cidr_ipv4 = "   "
          }
        }
      }
    }
  }
  expect_failures = [var.ecs_services]
}

run "reject_whitespace_security_group" {
  command = plan
  variables {
    ecs_services = {
      gateway = {
        create = false
        security_group_rules = {
          ingress = {
            from_port                    = 8000
            to_port                      = 8000
            referenced_security_group_id = "   "
          }
        }
      }
    }
  }
  expect_failures = [var.ecs_services]
}

run "reject_empty_unused_cidr" {
  command = plan
  variables {
    ecs_services = {
      gateway = {
        create = false
        security_group_rules = {
          ingress = {
            from_port                    = 8000
            to_port                      = 8000
            cidr_ipv4                    = ""
            referenced_security_group_id = "sg-0123456789abcdef0"
          }
        }
      }
    }
  }
  expect_failures = [var.ecs_services]
}

run "reject_empty_unused_security_group" {
  command = plan
  variables {
    ecs_services = {
      gateway = {
        create = false
        security_group_rules = {
          ingress = {
            from_port                    = 8000
            to_port                      = 8000
            cidr_ipv4                    = "10.0.0.0/16"
            referenced_security_group_id = ""
          }
        }
      }
    }
  }
  expect_failures = [var.ecs_services]
}
