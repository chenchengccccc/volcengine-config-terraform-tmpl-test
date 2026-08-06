# 这是一个已经存在于 cn-shanghai 的 ENI，不是本模板准备创建的新 ENI。
# imports.tf 使用该变量把 ENI 绑定到 volcenginecc_vpc_eni.target。
variable "network_interface_id" {
  description = "需要追加安全组的上海地域现有辅助网卡 ID。"
  type        = string
}
