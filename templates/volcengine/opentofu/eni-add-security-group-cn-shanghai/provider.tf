# 平台不能动态传入 Provider Region，因此在模板中固定上海地域。
# AK、SK 和 SecurityToken 仍通过 VOLCENGINE_* 环境变量传入。
provider "volcenginecc" {
  region = "cn-shanghai"
}
