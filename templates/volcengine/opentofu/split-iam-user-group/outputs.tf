# 输出本次 Plan 读取到的源用户组快照。
output "source_snapshot" {
  description = "本次拆分读取到的原始用户和策略快照。"
  value = {
    source_group = var.old_group_name
    users        = local.snapshot_users
    policies = {
      for policy_key, policy in local.snapshot_policies : policy_key => policy.policy_name
    }
  }
}

# 新建的 primary 替代组承载排序后的第一个策略。
output "primary_group" {
  description = "替换旧组并承载第一个策略的新用户组。"
  value = {
    name       = volcenginecc_iam_group.primary.user_group_name
    policy_key = local.primary_policy_key
    policy     = local.primary_policy.policy_name
    users      = local.snapshot_users
  }
}

# 输出本模板新建的其余单策略用户组。
output "created_groups" {
  description = "为第二个到第 N 个策略创建的新用户组。"
  value = {
    for policy_key, group in volcenginecc_iam_group.split : policy_key => {
      id     = group.id
      name   = group.user_group_name
      policy = local.snapshot_policies[policy_key].policy_name
      users  = local.snapshot_users
    }
  }
}

# 最终新组数量应与旧组原始策略数量一致。
output "split_summary" {
  description = "拆分结果摘要。"
  value = {
    original_policy_count = length(local.snapshot_policies)
    final_group_count     = 1 + length(volcenginecc_iam_group.split)
  }
}
