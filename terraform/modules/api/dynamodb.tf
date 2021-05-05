resource "aws_dynamodb_table" "following_table" {
  name           = var.table_name
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  tags = {
    Name        = "following table"
    Environment = var.stage
  }
}
