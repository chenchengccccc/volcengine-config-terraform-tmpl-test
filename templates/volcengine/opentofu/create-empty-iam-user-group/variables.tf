variable "region" {
  description = "CloudControl 请求地域。"
  type        = string
  default     = "cn-guilin-boe"
}

variable "cloud_control_endpoint" {
  description = "CloudControl API 接入地址。"
  type        = string
  default     = "cloudcontrol.cn-guilin-boe.volcengineapi-test.com"
}

variable "user_group_name" {
  description = "需要创建的空 IAM 用户组名称。"
  type        = string

  validation {
    condition     = can(regex("^config-deploy-e2e-[a-z0-9-]{1,40}$", var.user_group_name))
    error_message = "user_group_name 必须以 config-deploy-e2e- 开头，且只能包含小写字母、数字和连字符。"
  }
}
