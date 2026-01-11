resource "aws_dynamodb_table" "certmagic" {
  count        = var.create_certmagic_table ? 1 : 0
  name         = "${local.cluster_name}-certmagic"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PrimaryKey"
  attribute {
    name = "PrimaryKey"
    type = "S"
  }
}