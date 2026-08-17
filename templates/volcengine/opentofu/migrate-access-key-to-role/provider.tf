# IAM 是全局服务，region 仍用于 CloudControl 请求签名。
# AK、SK 和 SecurityToken 仍通过 VOLCENGINE_* 环境变量传入。
provider "volcenginecc" {
  region = var.region

  endpoints = {
    cloudcontrolapi = var.cloud_control_endpoint
  }
}
