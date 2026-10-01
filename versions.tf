terraform {
  required_version = ">= 1.10, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "local" {}
  # ------ Bootstrap uses local state on purpose: it creates the bucket that
  # ------ every other stack stores its state in. Keep terraform.tfstate out
  # ------ of git (see .gitignore) and back it up after the first apply.
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Account   = var.account_name
      Project   = var.project
      ManagedBy = "terraform-bootstrap"
    }
  }
}
