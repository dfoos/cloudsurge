resource "aws_dynamodb_table" "token_table" {
  name           = "TokenStore"
  billing_mode   = "PAY_PER_REQUEST" # Keeps cost low for low-access patterns
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}