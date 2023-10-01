packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}


variable "region" {
  type        = string
  description = "The region of the AMI will be available"
  default     = "us-east-1"
}

variable "docker_username" {
  type        = string
  description = "username of docker hub"
}

variable "docker_password" {
  type        = string
  description = "password of docker hub"
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

# add source block using amazon-ebs as source type
source "amazon-ebs" "nomad" {
  ami_name      = "nomad-ec2-${local.timestamp}"
  instance_type = "t2.micro"
  region        = var.region

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
      root-device-type   = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["679593333241"]

  }
  ssh_username = "ubuntu"

}

# a build block invokes sources and runs provisioning steps on them.
build {
  sources = ["source.amazon-ebs.nomad"]

  provisioner "shell" {
    environment_vars = [
    "USERNAME=${var.docker_username}",
    "PASSWORD=${var.docker_password}"
  ]
    script = "./setup.sh"
  }
  provisioner "file" {
    source      = "./daemon.json"
    destination = "/tmp/daemon.json"
  }
  provisioner "shell" {
    script = "./move-daemon.sh"
  }
}