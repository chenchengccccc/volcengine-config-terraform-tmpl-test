# 当前模板操作的地域，通过 TF_VAR_region 环境变量注入。
variable "region" {
  description = "火山引擎地域。"
  type        = string
}

# 这是一个已经存在的 ENI，不是本模板准备创建的新 ENI。
# 首次运行前，必须使用 terraform import 将该 ENI 绑定到
# volcenginecc_vpc_eni.target；后续运行会从持久化 state 中找到该绑定关系。
variable "network_interface_id" {
  description = "需要追加安全组的现有辅助网卡 ID。"
  type        = string
}

# true：保留原安全组并追加实验安全组。
# false：从 ENI 的当前安全组集合中移除实验安全组，用于实验清理的第一阶段。
# 该变量不会控制安全组资源是否创建或删除。
variable "attach_new_security_group" {
  description = "true 表示关联实验安全组；false 表示解除关联，用于清理实验。"
  type        = bool
  default     = true
}
