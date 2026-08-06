# Outputs 会写入当前 Workspace 的 State，并可通过 tofu output 查看。
# Config 或 QA 可以用新安全组 ID 验证资源是否创建成功。
output "created_security_group_id" {
  description = "本实验创建的安全组 ID。"
  value       = volcenginecc_vpc_security_group.remediation.security_group_id
}

# 回显输入的目标 ENI，便于确认本次操作对象。
output "target_network_interface_id" {
  description = "实验目标 ENI ID。"
  value       = var.network_interface_id
}

# apply 后由 Provider 刷新得到的 ENI 最终安全组集合。
# 正常关联后应同时包含原安全组 ID 和 created_security_group_id。
output "target_security_group_ids" {
  description = "实验执行后 ENI 的安全组集合。"
  value       = volcenginecc_vpc_eni.target.security_group_ids
}
