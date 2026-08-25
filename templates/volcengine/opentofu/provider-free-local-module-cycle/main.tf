# 此模板故意形成包内本地 Module 环，仅用于验证 Config 同步预检。
module "loop" {
  source = "./loop"
}

resource "terraform_data" "marker" {
  input = var.marker
}
