# 回显目标 VPC 输入，便于确认本次日志采集范围。
output "target_vpc" {
  description = "流日志采集的现有 VPC。"
  value = {
    id           = var.vpc_id
    project_name = var.project_name
  }
}

# 输出新建的 TLS 日志项目。
output "log_project" {
  description = "本模板创建的 TLS 日志项目。"
  value = {
    id   = volcenginecc_tls_project.flow_log.project_id
    name = volcenginecc_tls_project.flow_log.project_name
  }
}

# 输出新建的 TLS 日志主题。
output "log_topic" {
  description = "本模板创建的 TLS 日志主题。"
  value = {
    id   = volcenginecc_tls_topic.flow_log.topic_id
    name = volcenginecc_tls_topic.flow_log.topic_name
  }
}

# 输出 VPC FlowLog 的 ID 和最终状态，用于验证日志投递关联已经创建。
output "flow_log" {
  description = "本模板创建的 VPC FlowLog。"
  value = {
    id     = volcenginecc_vpc_flow_log.target.flow_log_id
    status = volcenginecc_vpc_flow_log.target.status
  }
}
