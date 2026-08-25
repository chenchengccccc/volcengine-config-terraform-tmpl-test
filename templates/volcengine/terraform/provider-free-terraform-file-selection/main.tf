# 仅含 Terraform 内建 terraform_data，验证 Terraform 不解析同目录的 main.tofu。
resource "terraform_data" "from_tf" {
  input = "terraform-selected"
}
