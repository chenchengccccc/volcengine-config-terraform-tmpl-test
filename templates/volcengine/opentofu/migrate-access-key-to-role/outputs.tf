output "migration_summary" {
  description = "当前阶段及迁移对象摘要，不输出任何 Secret。"
  value = {
    source_user       = var.user_name
    source_access_key = var.access_key_id
    direct_policies = [
      for policy_key in sort(keys(local.source_policies)) : local.source_policies[policy_key]
    ]
    replacement_role = {
      name = volcenginecc_iam_role.replacement.role_name
      trn  = volcenginecc_iam_role.replacement.trn
    }
    access_key_action = var.delete_legacy_access_key ? "deleted" : "imported_and_retained"
  }
}
