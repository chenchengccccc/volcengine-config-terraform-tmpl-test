# TerraformCC Provider 初始化所使用的地域。
variable "region" {
  description = "火山引擎地域。"
  type        = string
}

# 唯一业务输入：需要按策略拆分的现有 IAM 用户组名。
variable "old_group_name" {
  description = "需要按已关联策略拆分的现有 IAM 用户组名。"
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]{1,64}$", var.old_group_name))
    error_message = "old_group_name 必须为 1 到 64 位，只能包含英文、数字和 .-_。"
  }
}
