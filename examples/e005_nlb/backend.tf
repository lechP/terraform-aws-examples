terraform {
  backend "s3" {
    bucket         = "lpi-tfstate-3e1989"
    key            = "examples/e005/terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "tf-locks"
    encrypt        = true
  }
}
