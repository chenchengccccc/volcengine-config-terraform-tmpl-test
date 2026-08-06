# 当前模板操作的地域，通过 TF_VAR_region 环境变量注入。
variable "region" {
  description = "火山引擎地域。"
  type        = string
}

# 这是一个已经存在的 ENI，不是本模板准备创建的新 ENI。
# imports.tf 使用该变量把 ENI 绑定到 volcenginecc_vpc_eni.target。
variable "network_interface_id" {
  description = "需要追加安全组的现有辅助网卡 ID。"
  type        = string
}
