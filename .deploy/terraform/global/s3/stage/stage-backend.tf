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

  bucket_name = "ahmed-stage-state-bucket"
  dynamodb_name = "ahmed-stage-table-locks"
}

# using backend for store tfstate in s3 with locking by dynamodb
terraform {
  backend "s3" {
    # set bucket details
    bucket = "ahmed-stage-state-bucket"
    key = "global/s3/stage/terraform.tfstate"
    region = "us-east-2"

    # dynamo db table details for locking
    dynamodb_table = "ahmed-stage-table-locks"
    encrypt = true
  }
}