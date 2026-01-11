locals {
  # This lifecycle rule in prod moves non-current versions (backups) to Glacier IR storage class and deletes them after 30 days
  backup_lifecycle_rule = [
    {
      id      = "BackupLifecycleRule"
      enabled = true
      noncurrent_version_expiration = {
        days = 30
      }
      expiration = {
        expired_object_delete_marker = true
      }
    }
  ]
}

module "s3_logs_bucket" {
  for_each = local.msk_map
  source   = "terraform-aws-modules/s3-bucket/aws"
  version  = "~> 5.8.2"

  create_bucket = each.value.create

  bucket = "${each.value.identifier}-logs"

  acl                      = "log-delivery-write"
  control_object_ownership = true
  object_ownership         = "ObjectWriter"
  versioning               = { enabled = true }

  lifecycle_rule = local.backup_lifecycle_rule

  attach_deny_insecure_transport_policy = true
  attach_lb_log_delivery_policy         = true # this allows log delivery

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
}