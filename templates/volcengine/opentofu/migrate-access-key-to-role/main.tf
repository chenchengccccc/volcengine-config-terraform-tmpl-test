# 读取测试用户的直接授权策略和 AccessKey 列表。
# 本实验不复制用户通过用户组继承的权限，因此要求使用没有加入用户组的专用测试用户。
data "volcenginecc_iam_user" "source" {
  id = var.user_name
}

locals {
  # 只复制直接关联到测试用户的策略，并用稳定键消除 Set 的遍历顺序影响。
  source_policies = {
    for policy in coalesce(data.volcenginecc_iam_user.source.policies, toset([])) :
    "${policy.policy_type}|${policy.policy_name}" => {
      policy_name = policy.policy_name
      policy_type = policy.policy_type
    }
  }

  # 迁移对象是 IAM 用户，因此收集该用户当前的全部 AccessKey，不区分启用或停用状态。
  source_access_keys = {
    for access_key in coalesce(data.volcenginecc_iam_user.source.access_key, toset([])) :
    access_key.access_key_id => true
  }

  # 默认名称只依赖 user_name，两个 Apply 会得到同一个 Role 资源。
  target_role_name = var.role_name != null ? var.role_name : format(
    "config-ak-role-%s",
    substr(sha256(var.user_name), 0, 12),
  )
}

# 把第一次 Apply 的迁移对象保存在 State 中。
# ignore_changes 确保第二次 Apply 读取的是第一次确认过的对象，而不是覆盖后的新变量。
resource "terraform_data" "migration_context" {
  input = {
    prepared       = !var.delete_legacy_access_keys
    user_name      = var.user_name
    access_key_ids = sort(keys(local.source_access_keys))
    role_name      = local.target_role_name
  }

  lifecycle {
    ignore_changes = [input]
  }
}

# 第一次 Apply：for_each 为用户的全部 AccessKey，imports.tf 会逐个 Import 并禁用。
# 第二次 Apply：for_each 变为空，State 中的全部 AccessKey 实例都会被计划删除。
resource "volcenginecc_iam_accesskey" "legacy" {
  for_each = var.delete_legacy_access_keys ? {} : local.source_access_keys

  user_name = var.user_name
  status    = "inactive"
}

# 创建替代长期 AccessKey 的 IAM Role，并复制测试用户的直接授权策略。
# Role 在两个 Apply 中始终使用同一资源地址和同一名称，因此第二次 Apply 会保留它。
resource "volcenginecc_iam_role" "replacement" {
  role_name            = local.target_role_name
  display_name         = "AccessKey 迁移实验 Role"
  description          = "由 Config OpenTofu 实验从 IAM 用户 ${var.user_name} 的直接授权迁移。"
  max_session_duration = 3600

  trust_policy_document = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = ["sts:AssumeRole"]
        Principal = {
          IAM = [format("trn:iam::%d:root", data.volcenginecc_iam_user.source.account_id)]
        }
      }
    ]
  })

  policies = [
    for policy_key in sort(keys(local.source_policies)) : {
      policy_name = local.source_policies[policy_key].policy_name
      policy_type = local.source_policies[policy_key].policy_type
    }
  ]

  lifecycle {
    precondition {
      condition     = length(coalesce(data.volcenginecc_iam_user.source.groups, toset([]))) == 0
      error_message = "测试用户加入了用户组；本实验不会复制用户组继承权限，请改用没有加入用户组的专用测试用户。"
    }

    precondition {
      condition     = length(local.source_policies) > 0
      error_message = "测试用户没有直接关联策略，无法验证权限迁移。"
    }

    precondition {
      condition     = var.delete_legacy_access_keys || length(local.source_access_keys) > 0
      error_message = "测试用户没有 AccessKey，不需要执行本迁移模板。"
    }

    precondition {
      condition = !var.delete_legacy_access_keys || (
        try(terraform_data.migration_context.output.prepared, false) &&
        try(terraform_data.migration_context.output.user_name, "") == var.user_name &&
        try(terraform_data.migration_context.output.role_name, "") == local.target_role_name &&
        (
          toset(try(terraform_data.migration_context.output.access_key_ids, [])) == toset(keys(local.source_access_keys)) ||
          length(local.source_access_keys) == 0
        )
      )
      error_message = "第二次 Apply 必须沿用第一次 Apply 的同一资源栈、user_name、AccessKey 集合和 role_name。"
    }
  }
}
