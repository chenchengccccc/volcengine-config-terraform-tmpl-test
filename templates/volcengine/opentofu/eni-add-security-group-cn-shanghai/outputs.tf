output "created_security_group_id" {
  description = "本实验创建的安全组 ID。"
  value       = volcenginecc_vpc_security_group.remediation.security_group_id
}

output "target_network_interface_id" {
  description = "实验目标 ENI ID。"
  value       = var.network_interface_id
}

output "target_security_group_ids" {
  description = "实验执行后 ENI 的安全组集合。"
  value       = volcenginecc_vpc_eni.target.security_group_ids
}
