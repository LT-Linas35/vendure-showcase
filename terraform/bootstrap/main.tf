module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "lino-terraform-state-bucket"
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }
}


resource "aws_dynamodb_table" "tf_lock" {
  name           = "terraform-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform Locks"
    Environment = "bootstrap"
  }
}
