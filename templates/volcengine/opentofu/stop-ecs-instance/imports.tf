# OpenTofu 1.11.8 的 import.id 不能直接引用输入变量。
# 使用单元素 for_each 后，可以通过 each.value 使用同一个 ECS 实例 ID。
import {
  for_each = {
    target = var.instance_id
  }

  to = volcenginecc_ecs_instance.target
  id = each.value
}
