# 第一步：只读查询现有 ECS 实例。
# data 块用于回填 managed resource 的创建必填属性，不会修改实例。
data "volcenginecc_ecs_instance" "target" {
  id = var.instance_id
}

# 第二步：将既有实例 Import 到当前独立 State，并声明最终状态为 STOPPED。
# 所有创建必填属性均取自刚读取的实例。可选属性则继续由 Import 后的 State 管理，
# 避免把 Provider 的只读字段或其他实例配置写入本次更新。
resource "volcenginecc_ecs_instance" "target" {
  image = {
    image_id = data.volcenginecc_ecs_instance.target.image.image_id
  }
  instance_name             = data.volcenginecc_ecs_instance.target.instance_name
  instance_type             = data.volcenginecc_ecs_instance.target.instance_type
  primary_network_interface = {}
  system_volume = {
    # 该字段在 schema 中有默认值；从现有实例回填，避免 Import 后发生替换。
    delete_with_instance = data.volcenginecc_ecs_instance.target.system_volume.delete_with_instance
  }
  zone_id = data.volcenginecc_ecs_instance.target.zone_id

  # 始终声明实例最终状态；只有用户显式传入时才覆盖停机模式。
  status       = "STOPPED"
  stopped_mode = var.stopped_mode

  lifecycle {
    # 该实例在模板外创建；即使误执行 tofu destroy，也绝不允许删除它。
    prevent_destroy = true

    # 仅接受稳定的运行或已停止状态；其他中间态可能与本次 Stop 操作竞争。
    precondition {
      condition     = contains(["RUNNING", "STOPPED"], data.volcenginecc_ecs_instance.target.status)
      error_message = "目标 ECS 必须处于 RUNNING 或 STOPPED 状态，当前存在进行中的或异常操作。"
    }
  }
}
