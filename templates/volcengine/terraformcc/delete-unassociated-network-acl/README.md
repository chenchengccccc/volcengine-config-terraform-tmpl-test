# 删除未关联子网的 Network ACL

## 目标

删除一个已有 Network ACL，但必须同时满足：

1. `resources` 关联资源集合为空；
2. ACL 状态为 `Available`；
3. Destroy Plan 只包含指定 ACL 的一个 Delete。

这是一个 `DELETE` 模板。Import 只建立 Terraform state 绑定，不修改云资源；真正的
删除发生在应用 Destroy Plan 时。

资源变化：

```text
执行前（云上）
VPC
├── Subnet A、Subnet B（保持不变）
└── Network ACL nacl-target
    └── associated_resources = {}  ← 只有为空才允许继续

terraform import
└── 只建立 State 绑定：volcenginecc_vpc_network_acl.target → nacl-target

terraform apply destroy.tfplan
└── DELETE nacl-target

执行后（云上）
VPC
├── Subnet A、Subnet B（保持不变）
└── Network ACL nacl-target（已删除）
```

## 安全边界

- 模板使用独立 state，只能放置一个待删除 ACL。
- `precondition` 会在 Plan 阶段读取最新关联关系；有关联子网时直接终止。
- 模板不会自动解除子网关联，关联中的 ACL 不属于本模板处理范围。
- 不要在 Import 前执行普通 `terraform plan` 或 `terraform apply`，否则 Terraform
  会把 managed resource 当成待创建的新 ACL。
- Destroy Plan 是关联关系的时间点快照，检查后应立即执行；最终仍以火山引擎删除
  接口的服务端校验为准。

## 初始化并指定目标

```bash
cd templates/volcengine/terraformcc/delete-unassociated-network-acl
source ../../../../.credentials.env

export TF_VAR_network_acl_id="nacl-xxxxxxxxxxxxxxxxxxxxxxxxx"

terraform init
terraform validate
terraform state list
```

不要使用示例占位 ID 执行后续命令。

首次执行时，`terraform state list` 提示 `No state file was found` 是正常现象。

## Import

把同一个环境变量传给 Import：

```bash
terraform import \
  volcenginecc_vpc_network_acl.target \
  "$TF_VAR_network_acl_id"
```

Import 的职责只是建立 state 绑定，本身不作为删除条件判断。即使 Import 成功，后续
Destroy Plan 仍会重新读取 ACL，并通过 `precondition` 判断是否允许删除。

Import 成功后检查：

```bash
terraform state list
terraform output
terraform state show data.volcenginecc_vpc_network_acl.target
```

预期 state 中只有：

```text
data.volcenginecc_vpc_network_acl.target
volcenginecc_vpc_network_acl.target
```

确认输出中的 `associated_resources` 为空。

## Destroy Plan

```bash
terraform plan -destroy -out=plans/destroy.tfplan
terraform show -no-color plans/destroy.tfplan
```

必须确认：

```text
Plan: 0 to add, 0 to change, 1 to destroy.
```

Destroy 目标必须只有：

```text
volcenginecc_vpc_network_acl.target
```

## 执行删除

这是不可恢复操作。确认 ACL ID、关联集合和 Destroy Plan 后，立即执行：

```bash
terraform apply plans/destroy.tfplan
terraform state list
```

## 取消删除

如果 Import 后决定不删除，使用 `state rm` 解除 Terraform 对 ACL 的管理，不会删除
云上 ACL：

```bash
terraform state rm volcenginecc_vpc_network_acl.target
```

解除后不要执行普通 Plan；模板中仍存在 managed resource 块，普通 Plan 会尝试创建
新的 Network ACL。
