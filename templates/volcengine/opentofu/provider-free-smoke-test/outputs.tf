output "marker" {
  description = "Infra Manager 成功执行时写入 State 的测试标记。"
  value       = terraform_data.smoke_test.output.marker
}
