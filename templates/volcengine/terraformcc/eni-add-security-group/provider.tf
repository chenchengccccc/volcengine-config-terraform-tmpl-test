# Provider 这里只接收地域。
# AK、SK 和 SecurityToken 通过 VOLCENGINE_* 环境变量传入，不写进模板或 state。
provider "volcenginecc" {
  region = var.region
}
