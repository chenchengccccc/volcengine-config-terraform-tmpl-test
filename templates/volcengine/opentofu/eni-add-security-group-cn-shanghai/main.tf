# 第一步：只读查询上海地域的现有 ENI。
# data 块不会创建或修改资源，它用于取得 ENI 所属 VPC、Project、
# 当前安全组集合以及是否为服务托管网卡。
data "volcenginecc_vpc_eni" "target" {
  id = var.network_interface_id
}

locals {
  # 根据 ENI ID 生成稳定后缀：
  # 同一个 ENI 多次运行会得到相同名称，不依赖随机数或执行次数。
  name_suffix = substr(sha256(var.network_interface_id), 0, 12)
}

# 第二步：在目标 ENI 所属 VPC 中创建新的安全组。
# VPC 和 Project 直接继承目标 ENI，保证后续可以建立关联。
# 本模板没有声明 ingress_permissions 或 egress_permissions，
# 因此新安全组本身不添加额外访问规则。
resource "volcenginecc_vpc_security_group" "remediation" {
  vpc_id              = data.volcenginecc_vpc_eni.target.vpc_id
  project_name        = data.volcenginecc_vpc_eni.target.project_name
  security_group_name = "config-remediation-${local.name_suffix}"
  description         = "Created by Config remediation test in cn-shanghai"
}

locals {
  # 将新建安全组 ID 包装成 Set，便于和 ENI 当前安全组集合做集合运算。
  # 安全组在 Plan 阶段尚未创建，因此此 ID 会显示为 known after apply。
  remediation_security_group_ids = toset([
    volcenginecc_vpc_security_group.remediation.security_group_id,
  ])

  # 当前安全组 ∪ 新安全组：保留所有原安全组并追加新安全组。
  # 这里传递的是完整终态集合，而不是单独执行“增加一个 ID”的动作。
  desired_security_group_ids = setunion(
    data.volcenginecc_vpc_eni.target.security_group_ids,
    local.remediation_security_group_ids,
  )
}

# 第三步：修改现有 ENI 的安全组集合。
# imports.tf 会在第一次 Apply 时建立资源地址与现有 ENI 的绑定。
# Import、新安全组 Create 和 ENI Update 会出现在同一个 OpenTofu Plan 中。
resource "volcenginecc_vpc_eni" "target" {
  project_name       = data.volcenginecc_vpc_eni.target.project_name
  security_group_ids = local.desired_security_group_ids

  lifecycle {
    # 即使误执行 tofu destroy，也禁止 OpenTofu 删除用户原有 ENI。
    prevent_destroy = true

    # 服务托管 ENI 由云产品维护，不作为本实验的修改目标。
    precondition {
      condition     = !data.volcenginecc_vpc_eni.target.service_managed
      error_message = "实验目标必须是非服务托管 ENI。"
    }

    # ENI 最终最多关联 5 个安全组；重复执行时已存在的新安全组不会重复计数。
    precondition {
      condition     = length(local.desired_security_group_ids) <= 5
      error_message = "目标 ENI 已达到安全组数量上限，停止实验。"
    }
  }
}
