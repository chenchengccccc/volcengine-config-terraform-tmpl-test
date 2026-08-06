# IAM 是全局服务，模板不接收地域参数；cn-beijing 只用于选择 Provider 请求端点。
# AK、SK 和 SecurityToken 仍通过 VOLCENGINE_* 环境变量传入。
provider "volcenginecc" {
  region = "cn-beijing"
}
