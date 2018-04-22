provider "aws" {
    region = "eu-west-3"
}

terraform {
  backend "s3" {
    bucket         = "pager-terraform"
    key            = "terraform.tfstate"
    region         = "eu-west-3"
    encrypt        = true
  }
}
