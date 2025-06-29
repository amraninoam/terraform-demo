terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "noama-tf-state-bucket"
    key            = "demo/nginx-alb/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "noama-terraform-locks"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment  = "Demo"
      ControllerBy = "Terraform"
    }
  }
}
