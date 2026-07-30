mock_provider "aws" {
  alias = "contract"
}

run "disabled_default_lifecycle_rule_is_omitted" {
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
        lifecycle_rule = [
          {
            id      = "clear-versioned-assets"
            enabled = false
          }
        ]
      }
    }
  }

  assert {
    condition = (
      length(local.lifecycle_rule_by_bucket["records"]) == 1 &&
      local.lifecycle_rule_by_bucket["records"][0].id == "abort-failed-uploads" &&
      local.lifecycle_rule_by_bucket["records"][0].enabled &&
      local.lifecycle_rule_by_bucket["records"][0].abort_incomplete_multipart_upload_days == 1
    )
    error_message = "A disabled default lifecycle rule must be omitted while valid default rules remain."
  }
}

run "disabled_default_lifecycle_rule_with_action_is_retained" {
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
        lifecycle_rule = [
          {
            id      = "clear-versioned-assets"
            enabled = false
            expiration = {
              days = 30
            }
          }
        ]
      }
    }
  }

  assert {
    condition = (
      length(local.lifecycle_rule_by_bucket["records"]) == 2 &&
      local.lifecycle_rule_by_bucket["records"][1].id == "clear-versioned-assets" &&
      !local.lifecycle_rule_by_bucket["records"][1].enabled &&
      local.lifecycle_rule_by_bucket["records"][1].expiration.days == 30
    )
    error_message = "A disabled lifecycle rule with an action must remain a valid explicit rule."
  }
}
