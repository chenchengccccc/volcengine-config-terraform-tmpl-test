# AK、SK 和 SecurityToken 通过 VOLCENGINE_* 环境变量传入。
# region 必须与待删除 Network ACL 所在地域一致。
provider "volcenginecc" {
  region = var.region
}
