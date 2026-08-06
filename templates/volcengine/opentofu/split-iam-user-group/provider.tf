# AK、SK 和 SecurityToken 通过 VOLCENGINE_* 环境变量传入。
# IAM 是全局服务；region 仍用于初始化 TerraformCC Provider。
provider "volcenginecc" {
  region = var.region
}
