variable "bucket_name" {
  description = "the name of the s3 bucket"
  type = string
}

variable "dynamodb_name" {
  description = "the name of the dynamo db for locking"
  type = string
}