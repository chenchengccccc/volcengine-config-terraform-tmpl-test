# 当前模板操作的地域。VPC、TLS 日志项目、日志主题和流日志必须位于该地域。
variable "region" {
  description = "火山引擎地域。"
  type        = string
}

# 这是一个已经存在的 VPC。
# 本模板通过该 ID 只读 VPC，并把它传给新建的 FlowLog；不会 Import、Update 或 Delete VPC。
variable "vpc_id" {
  description = "需要启用流日志的现有 VPC ID。"
  type        = string

  validation {
    condition     = startswith(var.vpc_id, "vpc-")
    error_message = "vpc_id 必须是以 vpc- 开头的 VPC ID。"
  }
}

# All：采集全部流量；Allow：只采集放通流量；Drop：只采集拒绝流量。
variable "traffic_type" {
  description = "需要采集的流量类型。"
  type        = string
  default     = "All"

  validation {
    condition     = contains(["All", "Allow", "Drop"], var.traffic_type)
    error_message = "traffic_type 只能是 All、Allow 或 Drop。"
  }
}

# 流日志的聚合采样周期，单位为分钟。
variable "aggregation_interval" {
  description = "流日志聚合采样周期，单位为分钟。"
  type        = number
  default     = 10

  validation {
    condition     = contains([1, 5, 10], var.aggregation_interval)
    error_message = "aggregation_interval 只能是 1、5 或 10。"
  }
}

# TLS 日志主题的数据保留天数。
variable "log_ttl" {
  description = "日志保留天数。"
  type        = number
  default     = 30

  validation {
    condition     = var.log_ttl >= 1 && var.log_ttl <= 3650
    error_message = "log_ttl 必须在 1 到 3650 之间。"
  }
}
