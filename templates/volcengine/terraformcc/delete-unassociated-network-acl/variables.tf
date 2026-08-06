# 待删除 Network ACL 所在地域。
variable "region" {
  description = "火山引擎地域。"
  type        = string
}

# 这是一个已经存在的 Network ACL。
# 模板先用该 ID 读取关联关系，再把同一 ID Import 到 managed resource。
variable "network_acl_id" {
  description = "待检查并删除的现有 Network ACL ID。"
  type        = string

  validation {
    condition     = startswith(var.network_acl_id, "nacl-")
    error_message = "network_acl_id 必须是以 nacl- 开头的 Network ACL ID。"
  }
}
