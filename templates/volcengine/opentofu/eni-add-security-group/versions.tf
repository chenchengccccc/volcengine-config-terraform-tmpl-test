terraform {
  # 本目录使用 OpenTofu 1.11.8 的配置式 Import for_each 语法。
  required_version = "= 1.11.8"

  # Backend 由执行环境决定：本地默认使用 local，托管平台可注入自己的 Backend。

  required_providers {
    volcenginecc = {
      source  = "volcengine/volcenginecc"
      version = "= 0.0.57"
    }
  }
}
