variable "user_name" {
  description = "持有待迁移 AccessKey 的测试 IAM 用户名。"
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9._@-]{1,64}$", var.user_name))
    error_message = "user_name 必须为 1 到 64 位，只能包含英文、数字和 .-_@。"
  }
}

variable "access_key_id" {
  description = "第二次 Apply 将删除的测试 AccessKey ID。"
  type        = string

  validation {
    condition     = length(trimspace(var.access_key_id)) > 0
    error_message = "access_key_id 不能为空。"
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

variable "delete_legacy_access_key" {
  description = "false：Import 并保留旧 AccessKey；true：从 State 对应配置中移除并删除旧 AccessKey。"
  type        = bool
  default     = false
}
