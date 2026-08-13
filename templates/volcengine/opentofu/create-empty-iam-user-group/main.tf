# 创建一个不含用户和策略的 IAM 用户组，用于验证纯 CREATE 修正链路。
resource "volcenginecc_iam_group" "target" {
  user_group_name = var.user_group_name
  display_name    = "Config Deploy E2E"
  description     = "Created by Config Deploy end-to-end validation."

  users             = []
  attached_policies = []
}
