# Terraform 1.15 引入的 action 语义：Config 仅应解析 terraform_data，
# 不把 action 扩展为资源或权限。此 fixture 只用于同步预检，不执行 Deploy。
resource "terraform_data" "marker" {
  input = var.marker
}

action "terraform_data" "validate_marker" {
  config {
    input = var.marker
  }
}
