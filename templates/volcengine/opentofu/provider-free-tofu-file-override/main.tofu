# 仅含 OpenTofu 内建 terraform_data，验证 main.tofu 覆盖同名 main.tf。
resource "terraform_data" "from_tofu" {
  input = "tofu-selected"
}
