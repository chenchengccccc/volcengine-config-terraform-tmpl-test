# 此模板仅用于验证 Config 预检会忽略暂未建模的 Terraform 语义。
# 其中只有 terraform_data 属于实际可识别资源，因此不会申请云资源权限。
resource "terraform_data" "marker" {
  input = var.marker
}

# 这些块需要保持 HCL 语法完整，但不应参与 Config 的资源清单或权限推导。
removed {
  from = terraform_data.legacy

  lifecycle {
    destroy = false
  }
}

ephemeral "terraform_data" "transient" {
  input = var.marker
}
