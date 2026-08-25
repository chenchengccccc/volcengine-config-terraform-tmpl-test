terraform {
  required_providers {
    volcenginecc = {
      source = "volcengine/volcenginecc"
    }
  }
}

resource "volcenginecc_ecs_keypair" "child" {}
