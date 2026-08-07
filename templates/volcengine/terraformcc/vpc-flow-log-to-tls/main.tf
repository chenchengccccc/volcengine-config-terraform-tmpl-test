# 只读现有 VPC 的所属项目，不 Import，也不取得该 VPC 的管理权。
data "volcenginecc_vpc_vpc" "target" {
  id = var.vpc_id
}

locals {
  # 使用 VPC ID 生成稳定且符合资源命名规则的后缀。
  # 同一个 VPC 重复运行会得到相同名称，便于 QA 定位和清理资源。
  name_suffix = substr(sha256(var.vpc_id), 0, 12)

  log_project_name = "config-vpc-flow-${local.name_suffix}"
  log_topic_name   = "config-vpc-flow-topic-${local.name_suffix}"
  flow_log_name    = "config-vpc-flow-${local.name_suffix}"

  # TLS Project 和 FlowLog 与目标 VPC 使用同一个 IAM Project。
  project_name = data.volcenginecc_vpc_vpc.target.project_name
}

# 第一步：为目标 VPC 创建独立的 TLS 日志项目。
# IAM Project 沿用现有 VPC，避免把新建资源放入错误的项目。
resource "volcenginecc_tls_project" "flow_log" {
  project_name     = local.log_project_name
  iam_project_name = local.project_name
  description      = "Created for VPC flow logs by TerraformCC remediation lab"
}

# 第二步：在上一步创建的日志项目中创建日志主题。
# project_id 引用了 TLS Project 创建后返回的 ID，因此 Terraform 会等待 Project
# 创建完成，再创建 Topic。
resource "volcenginecc_tls_topic" "flow_log" {
  project_id  = volcenginecc_tls_project.flow_log.project_id
  topic_name  = local.log_topic_name
  description = "Receives VPC flow logs created by TerraformCC remediation lab"

  # 一个分区用于本地实验，并开启自动分裂以适应后续日志写入量增长。
  shard_count     = 1
  ttl             = var.log_ttl
  auto_split      = true
  max_split_shard = 10
}

# 第三步：创建独立的 VPC FlowLog 资源，完成日志投递关联。
#
# 关联关系全部声明在新建的 FlowLog 上：
#   resource_id      -> 现有 VPC
#   log_project_name -> 新建 TLS Project
#   log_topic_name   -> 新建 TLS Topic
#
# 原 VPC 不需要 Import，也不会被 Update。Project、Topic 和 FlowLog 之间的资源
# 引用负责建立创建顺序；VPC Data Source 只读取所属 IAM Project。
resource "volcenginecc_vpc_flow_log" "target" {
  flow_log_name        = local.flow_log_name
  description          = "Collects traffic from ${var.vpc_id}"
  project_name         = local.project_name
  resource_type        = "vpc"
  resource_id          = var.vpc_id
  traffic_type         = var.traffic_type
  aggregation_interval = var.aggregation_interval

  # FlowLog Schema 使用日志项目名和主题名，而不是 ID。
  # 即使名称在 plan 阶段已经确定，资源属性引用仍会建立显式依赖。
  log_project_name = volcenginecc_tls_project.flow_log.project_name
  log_topic_name   = volcenginecc_tls_topic.flow_log.topic_name
}
