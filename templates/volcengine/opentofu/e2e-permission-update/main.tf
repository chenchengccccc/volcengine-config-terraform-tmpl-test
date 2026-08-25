# 只读取既有 e2e IAM Group；用于 Config 对 Deploy 权限快照的预检，不执行 remediation task。
data "volcenginecc_iam_group" "target" {
  id = var.target_group_name
}
