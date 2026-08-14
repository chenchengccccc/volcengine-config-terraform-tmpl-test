# IAM 是全局服务，region 仍用于 CloudControl 请求签名。
# AK、SK 和 SecurityToken 由 Infra Manager 通过 VOLCENGINE_* 环境变量注入。
provider "volcenginecc" {
  region = var.region

  endpoints = {
    cloudcontrolapi = var.cloud_control_endpoint
  }
}
