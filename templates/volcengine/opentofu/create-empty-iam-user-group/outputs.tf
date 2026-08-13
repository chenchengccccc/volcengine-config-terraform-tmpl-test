output "user_group_name" {
  description = "已创建的空 IAM 用户组名称。"
  value       = volcenginecc_iam_group.target.user_group_name
}
