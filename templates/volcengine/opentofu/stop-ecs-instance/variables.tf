# 当前模板默认使用 BOE 地域，也允许执行环境覆盖。
variable "region" {
  description = "火山引擎地域。"
  type        = string
  default     = "cn-guilin-boe"
}

variable "cloud_control_endpoint" {
  description = "CloudControl API 接入地址。"
  type        = string
  default     = "cloudcontrol.cn-guilin-boe.volcengineapi-test.com"
}

# 这是一个已经存在的 ECS 实例。
# imports.tf 使用该变量将实例绑定到 volcenginecc_ecs_instance.target。
variable "instance_id" {
  description = "待停止的现有 ECS 实例 ID。"
  type        = string

  validation {
    condition     = startswith(var.instance_id, "i-")
    error_message = "instance_id 必须是以 i- 开头的 ECS 实例 ID。"
  }
}

# 未传入时不覆盖云侧或控制台已有的默认停机策略。
variable "stopped_mode" {
  description = "可选停机模式：KeepCharging 保留计算资源并继续计费；StopCharging 回收计算资源并停止计算费用。未设置时不显式指定。"
  type        = string
  default     = null

  validation {
    condition     = var.stopped_mode == null || contains(["KeepCharging", "StopCharging"], var.stopped_mode)
    error_message = "stopped_mode 只能是 KeepCharging 或 StopCharging。"
  }
}
