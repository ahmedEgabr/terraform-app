variable "cidr_vpc" {
  description = "CIDR block for the VPC"
  default = "10.0.0.0/16"
}

variable "cidr_public_subnet_1" {
  description = "CIDR block for the public subnet 1"
  default = "10.0.0.0/24"
}

variable "cidr_public_subnet_2" {
  description = "CIDR block for the public subnet 2"
  default = "10.0.1.0/24"
}

variable "cidr_public_subnet_3" {
  description = "CIDR block for the public subnet 3"
  default = "10.0.3.0/24"
}

variable "cluster_name" {
  description = "The name to use for all the cluster reesources"
  type = string
}

variable "stripe_secret_key" {
  description = "The Stripe secret key"
  type = string
}

variable "web_app_url" {
  description = "Web app url to redirect user after payment"
  type = string
}

variable "web_hook_secret" {
  description = "The Stripe webhook secret"
  type = string
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type = number
  default = 8080
}

variable "instance_type" {
  description = "The type of EC2 Instances to run (e.g t2.Micro)"
  type = string
}

variable "min_size" {
  description = "The minimum number of EC2 instances in the ASG"
  type = number
}

variable "max_size" {
  description = "The maximum number of EC2 instances in the ASG"
  type = number
}

variable "log_profile_name" {
  description = "The logs profile for aws instance"
}

variable "dns_hosted_zone" {
  description = "The name of our dns hosted zone"
  default = "cagaros.com"
}

variable "dns_name" {
  description = "subdomain name"
}

variable "policy_name" {
  description = "stage cloudwatch policy name"
  type = string
}

variable "role_name" {
  description = "stage cloudwatch role name"
  type = string
}