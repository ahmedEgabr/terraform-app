terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
    }
  }
  required_version = "v1.5.4"
}

provider "aws" {
  region = "us-east-2"
}

# terraform backend remote for state data
terraform {
  backend "s3" {
    #set bucket details
    bucket = "ahmed-stage-state-bucket"
    key = "stage/services/webserveer-cluster/terraform.tfstate"
    region = "us-east-2"

    # dynamo db table deetails for locking
    dynamodb_table = "ahmed-stage-table-locks"
    encrypt = true
  }
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name = "webservers-stage"
  stripe_secret_key = var.stripe_secret_key
  web_app_url = var.web_app_url
  web_hook_secret = var.web_hook_secret

  policy_name = var.policy_name
  role_name = var.role_name

  dns_name = "dev-api"
  log_profile_name = "nomad_stage_logs_profile"

  instance_type = "t2.micro"
  min_size = 2
  max_size = 3
}