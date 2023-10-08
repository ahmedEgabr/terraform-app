terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
    }
  }
  required_version = "v1.5.4"
}

provider "aws" {
  region =  "us-east-2"
}

module "backend_config" {
  source = "../../../modules/backends/s3"

  bucket_name = "ahmed-prod-state-bucket"
  dynamodb_name = "ahmed-prod-table-locks"
}

# using backend for store tfstate in s3 with locking by dynamodb
terraform {
  backend "s3" {
    # set bucket details
    bucket = "ahmed-prod-state-bucket"
    key = "global/s3/prod/terraform.tfstate"
    region = "us-east-2"

    # dynamo db table details for locking
    dynamodb_table = "ahmed-prod-table-locks"
    encrypt = true
  }
}