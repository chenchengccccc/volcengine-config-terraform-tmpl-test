# OpenTofu：为现有 ENI 创建并追加安全组

## 目标

通过一次 Plan/Apply 完成：

```text
已有 ENI
   │
   ├── IMPORT：纳入当前独立 State
   ├── CREATE：在同一 VPC 创建新安全组
   └── MODIFY：当前安全组集合 ∪ 新安全组
```

与 Terraform 1.5.7 版本相比，不需要单独运行 `terraform import`。`imports.tf` 将 Import
放入正常 Plan；`data` 块读取 ENI 当前安全组，`setunion` 计算完整终态。

预期首次计划：

```text
Plan: 1 to import, 1 to add, 1 to change, 0 to destroy.
```

## 初始化并指定目标

```bash
cd templates/volcengine/opentofu/eni-add-security-group
source ../../../../.credentials.env

export TF_VAR_region="cn-beijing"
export TF_VAR_network_interface_id="eni-xxxxxxxxxxxxxxxxxxxxxxxxx"

tofu init
tofu validate
tofu state list
```

首次执行时 State 为空是正常现象。不要额外运行 `tofu import`。

## 一次 Plan/Apply 完成修正

```bash
tofu plan -out=plans/apply.tfplan
tofu show -no-color plans/apply.tfplan
```

必须确认计划包含：

```text
volcenginecc_vpc_eni.target                         Import + Update
volcenginecc_vpc_security_group.remediation        Create
```

执行保存的计划：

```bash
tofu apply plans/apply.tfplan
tofu output
tofu plan
```

最后一次 Plan 应为 `No changes.`。Import Block 可以保留，后续不会重复 Import。

## 清理实验

先从 ENI 的完整安全组集合中移除实验安全组：

```bash
export TF_VAR_attach_new_security_group=false
tofu plan -out=plans/detach.tfplan
tofu show -no-color plans/detach.tfplan
tofu apply plans/detach.tfplan
```

再解除 OpenTofu 对原 ENI 的管理，并删除实验安全组：

```bash
tofu state rm volcenginecc_vpc_eni.target
tofu plan -destroy -out=plans/destroy.tfplan
tofu show -no-color plans/destroy.tfplan
tofu apply plans/destroy.tfplan
tofu state list
```

Destroy 模式不会重新执行 Import Block。清理完成后不要执行普通 Plan，否则模板会重新
Import ENI 并准备创建实验安全组。
