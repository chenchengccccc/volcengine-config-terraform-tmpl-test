# Import 后可通过 terraform output 查看目标 ACL 和关联资源快照。
output "target_network_acl" {
  description = "待删除 Network ACL 的检查结果。"
  value = {
    id                   = data.volcenginecc_vpc_network_acl.target.network_acl_id
    name                 = data.volcenginecc_vpc_network_acl.target.network_acl_name
    vpc_id               = data.volcenginecc_vpc_network_acl.target.vpc_id
    status               = data.volcenginecc_vpc_network_acl.target.status
    associated_resources = coalesce(data.volcenginecc_vpc_network_acl.target.resources, toset([]))
  }
}
