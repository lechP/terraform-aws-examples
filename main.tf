terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "lpi-tfstate-3e1989"
    key            = "sandbox/test/terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "tf-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-west-3"
}
