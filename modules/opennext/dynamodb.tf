resource "aws_dynamodb_table" "revalidation" {
  count        = var.enable_dynamodb_cache ? 1 : 0
  name         = "${local.name}-revalidation"
  billing_mode = "PAY_PER_REQUEST"
  point_in_time_recovery {
    enabled = true
  }
  hash_key  = "tag"
  range_key = "path"

  attribute {
    name = "tag"
    type = "S"
  }

  attribute {
    name = "path"
    type = "S"
  }

  attribute {
    name = "revalidatedAt"
    type = "N"
  }

  global_secondary_index {
    name            = "revalidate"
    hash_key        = "path"
    range_key       = "revalidatedAt"
    projection_type = "ALL"
  }

  tags = local.tags
}