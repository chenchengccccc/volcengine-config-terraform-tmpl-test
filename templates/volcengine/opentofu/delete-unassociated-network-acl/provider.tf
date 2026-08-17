# AK、SK 和 SecurityToken 通过 VOLCENGINE_* 环境变量传入。
provider "volcenginecc" {
  region = var.region

  endpoints = {
    cloudcontrolapi = var.cloud_control_endpoint
  }
}
