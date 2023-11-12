resource "aws_dynamodb_table" "certmagic" {
  name         = "${local.cluster_name}-certmagic"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PrimaryKey"
  attribute {
    name = "PrimaryKey"
    type = "S"
  }
}