# AK、SK 和 SecurityToken 继续通过 VOLCENGINE_* 环境变量传入。
# region 决定 VPC 查询以及 TLS、FlowLog 资源的创建地域。
provider "volcenginecc" {
  region = var.region

  endpoints = {
    cloudcontrolapi = var.cloud_control_endpoint
  }
}
