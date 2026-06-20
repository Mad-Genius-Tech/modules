resource "aws_dynamodb_table" "conversations" {
  count        = var.enabled ? 1 : 0
  name         = "${module.context.id}-conversations"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  tags = local.tags
}
