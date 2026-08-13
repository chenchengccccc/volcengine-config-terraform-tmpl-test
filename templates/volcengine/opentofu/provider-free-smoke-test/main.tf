# terraform_data 由 OpenTofu 内置 Provider 提供，不需要访问外部 Provider Registry。
resource "terraform_data" "smoke_test" {
  input = {
    marker = var.marker
  }
}
