# Import Block 让 Import 进入可检查的 Plan，但 Destroy 模式不会处理尚未写入 State 的
# Import，因此本案例仍然需要先 Apply Import Plan，再 Apply Destroy Plan。
import {
  for_each = {
    target = var.network_acl_id
  }

  to = volcenginecc_vpc_network_acl.target
  id = each.value
}
