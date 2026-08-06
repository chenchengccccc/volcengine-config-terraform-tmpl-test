# 第一次 Apply 时把存量 AccessKey 纳入当前资源栈。
# 第二次 Apply 把 delete_legacy_access_key 设为 true 后，for_each 为空，不再执行 Import。
import {
  for_each = var.delete_legacy_access_key ? {} : {
    target = var.access_key_id
  }

  to = volcenginecc_iam_accesskey.legacy[each.key]
  id = each.value
}
