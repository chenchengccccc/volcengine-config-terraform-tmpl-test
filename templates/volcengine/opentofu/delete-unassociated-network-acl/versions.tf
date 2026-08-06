terraform {
  # 本目录使用 OpenTofu 1.11.8 的配置式 Import for_each 语法。
  required_version = "= 1.11.8"

  # 删除案例必须使用独立 State，避免 Destroy 影响其他实验。
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
