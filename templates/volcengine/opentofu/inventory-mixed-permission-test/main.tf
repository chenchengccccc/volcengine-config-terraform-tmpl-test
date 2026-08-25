terraform {
  required_providers {
    volcenginecc = {
      source = "volcengine/volcenginecc"
    }
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "volcenginecc" {
  alias = "target"
}

resource "volcenginecc_iam_group" "root" {
  provider = volcenginecc.target
}

data "volcenginecc_iam_users" "all" {}

resource "aws_s3_bucket" "unknown_provider" {}

module "child" {
  source = "./modules/child"
}
