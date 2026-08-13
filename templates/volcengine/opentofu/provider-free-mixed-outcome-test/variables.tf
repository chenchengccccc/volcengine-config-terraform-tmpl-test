variable "marker" {
  description = "当前修正对象的测试标记。"
  type        = string
}

variable "rejected_marker" {
  description = "与该标记相同时故意让部署失败。"
  type        = string
}
