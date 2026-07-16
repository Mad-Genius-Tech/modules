mock_provider "aws" {
  mock_data "aws_route53_zone" {
    defaults = {
      zone_id = "Z0123456789"
    }
  }

  mock_data "aws_lb" {
    defaults = {
      dns_name           = "internal-example.us-west-2.elb.amazonaws.com"
      zone_id            = "Z1H1FL5HABSF5"
      load_balancer_type = "application"
    }
  }
}

run "literal_alias" {
  command = plan

  variables {
    zones = {
      "example.com" = {
        records = {
          "www.example.com" = {
            type = "A"
            alias = {
              name    = "dualstack.example.us-west-2.elb.amazonaws.com"
              zone_id = "Z1H1FL5HABSF5"
            }
          }
        }
      }
    }
  }

  assert {
    condition     = aws_route53_record.record["example.com|www.example.com"].alias[0].name == "dualstack.example.us-west-2.elb.amazonaws.com"
    error_message = "Literal alias DNS names must be preserved."
  }

  assert {
    condition     = aws_route53_record.record["example.com|www.example.com"].alias[0].zone_id == "Z1H1FL5HABSF5"
    error_message = "Literal alias zone IDs must be preserved."
  }
}

run "application_load_balancer_alias" {
  command = plan

  variables {
    zones = {
      "example.com" = {
        records = {
          "internal.example.com" = {
            type = "A"
            alias = {
              application_load_balancer_name = "example-internal"
            }
          }
        }
      }
    }
  }

  assert {
    condition     = aws_route53_record.record["example.com|internal.example.com"].alias[0].name == "dualstack.internal-example.us-west-2.elb.amazonaws.com"
    error_message = "ALB aliases must use the resolved dualstack DNS name."
  }

  assert {
    condition     = aws_route53_record.record["example.com|internal.example.com"].alias[0].zone_id == "Z1H1FL5HABSF5"
    error_message = "ALB aliases must use the resolved canonical hosted-zone ID."
  }
}

run "reject_partial_literal_alias" {
  command = plan

  variables {
    zones = {
      "example.com" = {
        records = {
          "partial.example.com" = {
            type = "A"
            alias = {
              name = "dualstack.example.us-west-2.elb.amazonaws.com"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.zones]
}

run "reject_blank_alb_name" {
  command = plan

  variables {
    zones = {
      "example.com" = {
        records = {
          "blank.example.com" = {
            type = "A"
            alias = {
              application_load_balancer_name = " "
            }
          }
        }
      }
    }
  }

  expect_failures = [var.zones]
}

run "reject_mixed_alias_forms" {
  command = plan

  variables {
    zones = {
      "example.com" = {
        records = {
          "mixed.example.com" = {
            type = "A"
            alias = {
              name                           = "dualstack.example.us-west-2.elb.amazonaws.com"
              zone_id                        = "Z1H1FL5HABSF5"
              application_load_balancer_name = "example-internal"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.zones]
}

run "reject_incompatible_alb_record_type" {
  command = plan

  variables {
    zones = {
      "example.com" = {
        records = {
          "internal.example.com" = {
            type = "CNAME"
            alias = {
              application_load_balancer_name = "example-internal"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.zones]
}
