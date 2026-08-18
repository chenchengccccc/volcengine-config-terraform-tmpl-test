# PR05 容量测试：provider-free terraform_data，附带超大 locals 字面量把模板包撑到 ~5MB。
resource "terraform_data" "smoke_test" {
  input = {
    marker = var.marker
    bulk   = length(local.bulk_payload)
  }
}
