terraform {
  # 保持与当前本地实验环境一致，使用 Terraform 1.5.7 即可执行。
  required_version = ">= 1.5.0"

  # Backend 由执行环境决定：本地默认使用 local，托管平台可注入自己的 Backend。

  # 固定 TerraformCC Provider 版本，保证 QA 执行结果一致。
  required_providers {
    volcenginecc = {
      source  = "volcengine/volcenginecc"
      version = "= 0.0.57"
    }
  }
}
