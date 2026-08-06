terraform {
  # 本目录使用 OpenTofu 1.11.8 的配置式 Import for_each 语法。
  required_version = "= 1.11.8"

  # 每个案例使用独立 State，不能与 Terraform 1.5.7 案例共用。
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
