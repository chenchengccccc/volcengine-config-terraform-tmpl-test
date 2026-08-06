terraform {
  # 保持与当前本地实验环境一致，使用 Terraform 1.5.7 即可执行。
  required_version = ">= 1.5.0"

  # 迁移模板必须使用独立 state，避免旧用户组的 Delete 影响其他实验。
  backend "local" {
    path = "state/terraform.tfstate"
  }

  # 固定 TerraformCC Provider 版本，保证 QA 执行结果一致。
  required_providers {
    volcenginecc = {
      source  = "volcengine/volcenginecc"
      version = "= 0.0.57"
    }
  }
}
