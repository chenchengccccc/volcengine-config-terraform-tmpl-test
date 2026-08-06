# 为现有 VPC 部署流日志并投递到 TLS

## 目标

1. 接收现有 VPC ID，不 Import、不修改 VPC。
2. 在 VPC 所属 IAM Project 中创建 TLS 日志项目。
3. 在日志项目中创建日志主题。
4. 创建 VPC FlowLog，并通过资源引用投递到上述日志主题。

资源关系：

```text
TLS Project ──project_id──> TLS Topic
     │                          │
     │ project_name             │ topic_name
     └────────────┬─────────────┘
                  ▼
             VPC FlowLog <──resource_id── 现有 VPC ID（输入）
```

预期计划：

```text
Plan: 3 to add, 0 to change, 0 to destroy.
```

## 前置条件

- 账号已开通 TLS 日志服务。
- 账号已完成 VPC 流日志访问 TLS 的跨服务授权。
- 目标 VPC 与 Provider 的 `region` 位于同一地域。

如果账号从未使用过 VPC 流日志，需要先在控制台完成一次跨服务访问授权；该授权
是账号级前置条件，不是对目标 VPC 的 Update。

## 初始化和 Plan

Terraform 会自动把 `TF_VAR_<变量名>` 映射到同名输入变量。进入模板后先设置本次
实验的三个必填参数：

```bash
cd templates/volcengine/terraformcc/vpc-flow-log-to-tls
source ../../../../.credentials.env

export TF_VAR_region="cn-beijing"
export TF_VAR_vpc_id="vpc-xxxxxxxxxxxxxxxxxxxxxxxxx"
export TF_VAR_project_name="default"

terraform init
terraform validate
terraform state list
terraform plan -out=plans/apply.tfplan
terraform show -no-color plans/apply.tfplan
```

可选参数不设置时使用 `variables.tf` 中的默认值；需要覆盖时同样通过环境变量注入：

```bash
export TF_VAR_traffic_type="All"
export TF_VAR_aggregation_interval=10
export TF_VAR_log_ttl=30
```

环境变量只作用于当前 Shell；打开新终端后需要重新 `source` 凭证并执行上述 `export`。

首次执行时，`terraform state list` 提示 `No state file was found` 是正常现象。该模板
不需要执行 `terraform import`，目标 VPC 也不会进入 Terraform state。

确认 Plan 只包含以下三个 Create：

```text
volcenginecc_tls_project.flow_log
volcenginecc_tls_topic.flow_log
volcenginecc_vpc_flow_log.target
```

不应出现 `volcenginecc_vpc_vpc` 的 Create、Update 或 Delete；目标 VPC ID 只作为
`volcenginecc_vpc_flow_log.target.resource_id` 的输入。

## Apply

确认 Plan 后再执行：

```bash
terraform apply plans/apply.tfplan
terraform output
terraform plan
```

最后一次 Plan 预期为 `No changes.`。

Terraform 根据资源引用依次创建 TLS Project、TLS Topic 和 VPC FlowLog。FlowLog
创建完成后，火山引擎会按照采样周期把目标 VPC 的流量日志投递到日志主题。

## 索引说明

该模板只验证日志投递关系，不创建 TLS Index。没有索引不影响日志写入，但日志在
配置索引前不能用于检索分析。如果 QA 还需要验证检索，可以后续增加一个独立的
`volcenginecc_tls_index` 资源。

## 清理

先生成并检查销毁计划：

```bash
terraform plan -destroy -out=plans/destroy.tfplan
terraform show -no-color plans/destroy.tfplan
terraform apply plans/destroy.tfplan
terraform state list
```

Terraform 会按照依赖关系反向删除：

```text
VPC FlowLog -> TLS Topic -> TLS Project
```

现有 VPC 不在 managed state 中，不会被删除或修改。
