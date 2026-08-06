terraform {
  # 与其他对比案例统一固定 OpenTofu 1.11.8；本案例本身不需要 Import。
  required_version = "= 1.11.8"

  backend "local" {
    path = "state/terraform.tfstate"
  }

  required_providers {
    volcenginecc = {
      source  = "volcengine/volcenginecc"
      version = "= 0.0.57"
    }
  }
}
