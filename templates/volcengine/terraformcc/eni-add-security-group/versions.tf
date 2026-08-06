terraform {
  # 约束 Terraform CLI 版本，避免使用过旧版本执行该模板。
  required_version = ">= 1.5.0"

  # 使用本地 Backend，并将该模板的资源状态持久化在模板自己的 state 目录中。
  # 每个模板都是独立的 Terraform root module，因此不会与其他模板共享 state。
  backend "local" {
    path = "state/terraform.tfstate"
  }

  # 固定 TerraformCC Provider 版本，避免 QA 环境自动升级后产生行为差异。
  # 实际安装版本及包校验值同时记录在 .terraform.lock.hcl 中。
  required_providers {
    volcenginecc = {
      source  = "volcengine/volcenginecc"
      version = "= 0.0.57"
    }
  }
}
