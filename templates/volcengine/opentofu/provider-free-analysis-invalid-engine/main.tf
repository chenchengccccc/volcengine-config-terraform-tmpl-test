# 合法的 provider-free 模板；测试通过 contract 中不支持的 engine 版本触发预检失败。
resource "terraform_data" "marker" {
  input = var.marker
}
