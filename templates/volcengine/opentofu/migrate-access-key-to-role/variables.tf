variable "user_name" {
  description = "持有待迁移 AccessKey 的测试 IAM 用户名。"
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9._@-]{1,64}$", var.user_name))
    error_message = "user_name 必须为 1 到 64 位，只能包含英文、数字和 .-_@。"
  }
}

variable "role_name" {
  description = "新 IAM Role 名称；不指定时根据 user_name 生成稳定名称。"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.role_name == null || can(
      regex("^[A-Za-z0-9._-]{1,64}$", var.role_name)
    )
    error_message = "role_name 必须为 1 到 64 位，只能包含英文、数字和 .-_。"
  }
}

variable "delete_legacy_access_keys" {
  description = "false：Import 并禁用用户的全部 AccessKey；true：从配置中移除并删除这些 AccessKey。"
  type        = bool
  default     = false
}
