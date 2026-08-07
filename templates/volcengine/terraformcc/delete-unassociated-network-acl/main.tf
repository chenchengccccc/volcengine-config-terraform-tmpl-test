# 第一步：读取待删除 Network ACL 的最新云上状态。
# resources 是 ACL 当前关联的子网集合；data 块本身不会修改 ACL。
data "volcenginecc_vpc_network_acl" "target" {
  id = var.network_acl_id
}

# 第二步：声明待 Import 的 managed resource。
#
# 这个 resource 块没有可配置的 Network ACL ID。首次执行时必须先运行
# terraform import，将 var.network_acl_id 对应的云资源绑定到这个地址。
#
# 严禁在 Import 前执行普通 terraform apply：Terraform 会把它当作待创建资源。
resource "volcenginecc_vpc_network_acl" "target" {
  # vpc_id 是创建 Network ACL 时的必填字段；这里从现有 ACL 的只读结果取得。
  # Destroy 不会修改或删除该 VPC。
  vpc_id = data.volcenginecc_vpc_network_acl.target.vpc_id

  lifecycle {
    # 只有关联资源集合为空时，才允许 Terraform 为该 ACL 生成操作计划。
    # Provider 会把“没有关联资源”读取为 null，因此需要先归一为空集合。
    # 如果 ACL 仍关联任意子网，Plan 会直接失败，不会进入 Destroy。
    precondition {
      condition     = length(coalesce(data.volcenginecc_vpc_network_acl.target.resources, toset([]))) == 0
      error_message = "Network ACL 仍关联子网，禁止删除。"
    }

    # 只允许删除处于 Available 状态的 Network ACL。
    precondition {
      condition     = data.volcenginecc_vpc_network_acl.target.status == "Available"
      error_message = "Network ACL 当前不是 Available 状态，禁止删除。"
    }
  }
}
