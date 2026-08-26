# Apply 后输出目标实例的最终状态，便于核验并作为执行记录。
output "target_ecs_instance" {
  description = "停止操作后的目标 ECS 实例摘要。"
  value = {
    id           = volcenginecc_ecs_instance.target.instance_id
    name         = volcenginecc_ecs_instance.target.instance_name
    status       = volcenginecc_ecs_instance.target.status
    stopped_mode = volcenginecc_ecs_instance.target.stopped_mode
    zone_id      = volcenginecc_ecs_instance.target.zone_id
  }
}
