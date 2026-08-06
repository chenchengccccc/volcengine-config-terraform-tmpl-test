# 第一步：读取待删除 Network ACL 的最新云上状态。
# resources 是 ACL 当前关联的子网集合；data 块本身不会修改 ACL。
data "volcenginecc_vpc_network_acl" "target" {
  id = var.network_acl_id
}

# 第二步：声明待 Import 的 managed resource。
# imports.tf 会在正常 Plan 中把 var.network_acl_id 绑定到这个地址。
# 首次 Apply 只执行 Import；完成后才能生成 Destroy Plan。
resource "volcenginecc_vpc_network_acl" "target" {
  # vpc_id 是创建 Network ACL 时的必填字段；这里从现有 ACL 的只读结果取得。
  # Destroy 不会修改或删除该 VPC。
  vpc_id = data.volcenginecc_vpc_network_acl.target.vpc_id

  lifecycle {
    # 只有关联资源集合为空时，才允许 Terraform 为该 ACL 生成操作计划。
    # 如果 ACL 仍关联任意子网，Plan 会直接失败，不会进入 Destroy。
    precondition {
      condition     = length(data.volcenginecc_vpc_network_acl.target.resources) == 0
      error_message = "Network ACL 仍关联子网，禁止删除。"
    }

    # 只允许删除处于 Available 状态的 Network ACL。
    precondition {
      condition     = data.volcenginecc_vpc_network_acl.target.status == "Available"
      error_message = "Network ACL 当前不是 Available 状态，禁止删除。"
    }
  }
}
