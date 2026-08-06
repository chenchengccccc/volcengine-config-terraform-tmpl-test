terraform {
  # 约束 Terraform CLI 版本，避免使用过旧版本执行该模板。
  required_version = ">= 1.5.0"

  # Backend 由执行环境决定：本地默认使用 local，托管平台可注入自己的 Backend。

  # 固定 TerraformCC Provider 版本，避免 QA 环境自动升级后产生行为差异。
  # 实际安装版本及包校验值同时记录在 .terraform.lock.hcl 中。
  required_providers {
    volcenginecc = {
      source  = "volcengine/volcenginecc"
      version = "= 0.0.57"
    }
  }
}
