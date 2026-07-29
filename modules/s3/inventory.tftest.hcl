mock_provider "aws" {
  alias = "contract"
}

run "inventory_configuration_uses_safe_defaults" {
  command = plan

  providers = {
    aws = aws.contract
  }

  variables {
    org_name     = "example"
    stage_name   = "dev"
    service_name = "archive"
    team_name    = "platform"
    s3_buckets = {
      records = {
        inventory = {
          destination_bucket_arn = "arn:aws:s3:::example-inventory-destination"
        }
      }
    }
  }

  assert {
    condition = (
      aws_s3_bucket_inventory.inventory["records"].enabled &&
      aws_s3_bucket_inventory.inventory["records"].included_object_versions == "All" &&
      aws_s3_bucket_inventory.inventory["records"].schedule[0].frequency == "Daily" &&
      aws_s3_bucket_inventory.inventory["records"].destination[0].bucket[0].format == "CSV"
    )
    error_message = "Explicit inventory configuration must create an all-versions daily CSV inventory with safe defaults."
  }
}

run "inventory_is_opt_in" {
  command = plan

  providers = {
    aws = aws.contract
  }

  variables {
    org_name     = "example"
    stage_name   = "dev"
    service_name = "archive"
    team_name    = "platform"
    s3_buckets = {
      records = {}
    }
  }

  assert {
    condition     = length(aws_s3_bucket_inventory.inventory) == 0
    error_message = "Buckets without inventory configuration must not create an inventory resource."
  }
}

run "invalid_inventory_frequency_is_rejected" {
  command = plan

  providers = {
    aws = aws.contract
  }

  variables {
    org_name     = "example"
    stage_name   = "dev"
    service_name = "archive"
    team_name    = "platform"
    s3_buckets = {
      records = {
        inventory = {
          destination_bucket_arn = "arn:aws:s3:::example-inventory-destination"
          frequency              = "Hourly"
        }
      }
    }
  }

  expect_failures = [var.s3_buckets]
}
