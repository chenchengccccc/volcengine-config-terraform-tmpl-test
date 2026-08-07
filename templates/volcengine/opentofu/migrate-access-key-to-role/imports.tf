# 第一次 Apply 时把用户的全部存量 AccessKey 纳入当前资源栈。
# 第二次 Apply 把 delete_legacy_access_keys 设为 true 后，for_each 为空，不再执行 Import。
import {
  for_each = var.delete_legacy_access_keys ? {} : local.source_access_keys

  to = volcenginecc_iam_accesskey.legacy[each.key]
  id = each.key
}
