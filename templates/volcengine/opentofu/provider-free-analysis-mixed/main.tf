# 此模板仅供 Config 在预检阶段分析：terraform_data 是 OpenTofu 内置 Provider，执行不会创建云资源。
resource "terraform_data" "marker" {
  input = var.marker
}

# 非平台 Provider、远程 Module、provisioner 与 check 不应阻断 Config 对可识别内置资源的预检。
terraform {
  required_providers {
    custom = {
      source = "example.invalid/custom"
    }
  }
}

module "remote_ignored" {
  source = "example.invalid/ignored/module"
}

check "marker_present" {
  assert {
    condition     = var.marker != ""
    error_message = "marker is required"
  }
}
