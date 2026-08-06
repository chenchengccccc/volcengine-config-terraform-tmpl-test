# OpenTofu：为现有 VPC 部署流日志并投递到 TLS

## 目标

这个案例是纯 DEPLOY，不需要 Import，也不修改现有 VPC：

```text
TLS Project ──project_id──> TLS Topic
     │                          │
     └────────────┬─────────────┘
                  ▼
             VPC FlowLog <──resource_id── 已有 VPC ID
```

OpenTofu 1.11.8 与 Terraform 1.5.7 的执行流程相同，都是一次 Plan/Apply，预期：

```text
Plan: 3 to add, 0 to change, 0 to destroy.
```

## 初始化并指定目标

```bash
cd templates/volcengine/opentofu/vpc-flow-log-to-tls
source ../../../../.credentials.env

export TF_VAR_region="cn-beijing"
export TF_VAR_vpc_id="vpc-xxxxxxxxxxxxxxxxxxxxxxxxx"
export TF_VAR_project_name="default"

tofu init
tofu validate
tofu state list
```

可选参数：

```bash
export TF_VAR_traffic_type="All"
export TF_VAR_aggregation_interval=10
export TF_VAR_log_ttl=30
```

## Plan/Apply

```bash
tofu plan -out=plans/apply.tfplan
tofu show -no-color plans/apply.tfplan
```

确认只创建：

```text
volcenginecc_tls_project.flow_log
volcenginecc_tls_topic.flow_log
volcenginecc_vpc_flow_log.target
```

现有 VPC 不应出现在 Create、Update 或 Delete 中。

```bash
tofu apply plans/apply.tfplan
tofu output
tofu plan
```

最后一次 Plan 应为 `No changes.`。

## 清理

```bash
tofu plan -destroy -out=plans/destroy.tfplan
tofu show -no-color plans/destroy.tfplan
tofu apply plans/destroy.tfplan
tofu state list
```

OpenTofu 按依赖关系反向删除 `FlowLog → Topic → Project`。已有 VPC 不在 managed State
中，不会被删除或修改。
