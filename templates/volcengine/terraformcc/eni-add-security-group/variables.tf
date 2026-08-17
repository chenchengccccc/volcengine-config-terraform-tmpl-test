# 当前模板默认使用 BOE 地域，也允许执行环境覆盖。
variable "region" {
  description = "火山引擎地域。"
  type        = string
  default     = "cn-guilin-boe"
}

variable "cloud_control_endpoint" {
  description = "CloudControl API 接入地址。"
  type        = string
  default     = "cloudcontrol.cn-guilin-boe.volcengineapi-test.com"
}

# 这是一个已经存在的 ENI，不是本模板准备创建的新 ENI。
# 首次运行前，必须使用 terraform import 将该 ENI 绑定到
# volcenginecc_vpc_eni.target；后续运行会从持久化 state 中找到该绑定关系。
variable "network_interface_id" {
  description = "需要追加安全组的现有辅助网卡 ID。"
  type        = string
}
