output "marker" {
  description = "部署成功时写入 State 的测试标记。"
  value       = terraform_data.mixed_outcome_test.output
}
