# 读取旧用户组的全部成员和已关联策略。
# 这也是使用者唯一需要指定的存量资源。
data "volcenginecc_iam_group" "source" {
  id = var.old_group_name
}

locals {
  # 对旧组成员和策略做一次结构化快照。
  # 当前模板只处理全局授权，避免复制项目授权中的关联时间等只读字段。
  source_users = sort([
    for user in coalesce(data.volcenginecc_iam_group.source.users, toset([])) : user.user_name
  ])
  source_policies = {
    for policy in coalesce(data.volcenginecc_iam_group.source.attached_policies, toset([])) :
    "${policy.policy_type}|${policy.policy_name}" => {
      policy_name = policy.policy_name
      policy_type = policy.policy_type
      is_global = alltrue([
        for scope in coalesce(policy.policy_scope, toset([])) : scope.policy_scope_type == "Global"
      ])
    }
  }
}

locals {
  # 本模板只执行一次迁移，Plan 直接使用数据源读取到的源组快照。
  # 不经过 managed resource，确保首次 Import 时 for_each 的键已经可知。
  snapshot_users    = local.source_users
  snapshot_policies = local.source_policies
  policy_keys       = sort(keys(local.snapshot_policies))

  # 排序后的第一个策略由 primary 替代组承载；其余策略分别创建一个新组。
  primary_policy_key = try(local.policy_keys[0], "")
  primary_policy = try(local.snapshot_policies[local.primary_policy_key], {
    policy_name = ""
    policy_type = ""
    is_global   = false
  })
  additional_policies = {
    for policy_key in slice(
      local.policy_keys,
      min(1, length(local.policy_keys)),
      length(local.policy_keys),
    ) : policy_key => local.snapshot_policies[policy_key]
  }

  # 所有替代组名称只由旧组名和策略标识决定，同一输入会得到同一个名称。
  target_group_names = {
    for policy_key, policy in local.snapshot_policies :
    policy_key => format(
      "split-%s-%s",
      substr(replace(lower(policy.policy_name), "/[^a-z0-9._-]/", "-"), 0, 40),
      substr(sha256("${var.old_group_name}|${policy_key}"), 0, 8),
    )
  }
}

# 用一个新名称的单策略组替换旧组。
# imports.tf 会在同一个 Plan 中把旧组绑定到这个地址；名称差异随后触发替换。
resource "volcenginecc_iam_group" "primary" {
  user_group_name = local.target_group_names[local.primary_policy_key]
  display_name    = substr("拆分组-${local.primary_policy.policy_name}", 0, 64)
  description     = substr("由 ${var.old_group_name} 按策略拆分：${local.primary_policy.policy_name}", 0, 128)

  users = [
    for user_name in local.snapshot_users : {
      user_name = user_name
    }
  ]
  attached_policies = [
    {
      policy_name  = local.primary_policy.policy_name
      policy_type  = local.primary_policy.policy_type
      policy_scope = []
    }
  ]

  # 先完成其余新组及关联，再创建 primary 替代组。
  depends_on = [volcenginecc_iam_group.split]

  lifecycle {
    # 当 Plan 判定 primary 必须替换时，先创建新组，再删除 Import 进来的旧组。
    # 该设置只调整替换顺序，本身不会触发替换。
    create_before_destroy = true

    precondition {
      condition     = length(local.snapshot_users) > 0
      error_message = "旧用户组没有成员，不需要执行本拆分模板。"
    }

    precondition {
      condition     = length(local.snapshot_policies) >= 2
      error_message = "旧用户组至少需要关联两个策略，才能拆分为多个单策略组。"
    }

    precondition {
      condition = alltrue([
        for policy in values(local.snapshot_policies) : policy.is_global
      ])
      error_message = "当前简化模板只支持全局授权策略，不处理按 IAM Project 授权的策略。"
    }
  }
}

# 为第二个到第 N 个策略分别创建一个新组。
# 每个新组都复制旧组的全部用户，并只关联当前一个策略。
resource "volcenginecc_iam_group" "split" {
  for_each = local.additional_policies

  user_group_name = local.target_group_names[each.key]
  display_name    = substr("拆分组-${each.value.policy_name}", 0, 64)
  description     = substr("由 ${var.old_group_name} 按策略拆分：${each.value.policy_name}", 0, 128)

  users = [
    for user_name in local.snapshot_users : {
      user_name = user_name
    }
  ]
  attached_policies = [
    {
      policy_name  = each.value.policy_name
      policy_type  = each.value.policy_type
      policy_scope = []
    }
  ]
}
