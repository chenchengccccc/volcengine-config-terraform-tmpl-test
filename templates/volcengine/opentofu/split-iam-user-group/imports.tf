# 把旧组的 Import 放入正常 Plan。Apply 会先 Import 旧组，再按 main.tf 中的新名称
# 对同一资源地址执行 create_before_destroy 替换。
import {
  for_each = {
    primary = var.old_group_name
  }

  to = volcenginecc_iam_group.primary
  id = each.value
}
