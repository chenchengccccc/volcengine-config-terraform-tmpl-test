# OpenTofu：删除未关联子网的 Network ACL

## 目标

只删除同时满足以下条件的已有 Network ACL：

1. `resources` 关联资源集合为空；
2. ACL 状态为 `Available`；
3. Destroy Plan 只包含指定 ACL 的一个 Delete。

```text
第一次 Plan/Apply
    IMPORT 已有 ACL
           ↓
第二次 Destroy Plan/Apply
    DELETE 已导入 ACL
```

OpenTofu 的 Import Block 只在正常 Plan 中处理，Destroy Plan 不会导入空 State 中的
资源。因此这个案例仍然是两个 Apply，不能合并成一次。

## 初始化并指定目标

```bash
cd templates/volcengine/opentofu/delete-unassociated-network-acl
source ../../../../.credentials.env

export TF_VAR_region="cn-beijing"
export TF_VAR_network_acl_id="nacl-xxxxxxxxxxxxxxxxxxxxxxxxx"

tofu init
tofu validate
tofu state list
```

## 第一次 Apply：Import

```bash
tofu plan -out=plans/import.tfplan
tofu show -no-color plans/import.tfplan
```

Plan 会读取 ACL 最新状态。只有 `associated_resources` 为空且状态为 `Available` 时才能
继续。预期只包含：

```text
Plan: 1 to import, 0 to add, 0 to change, 0 to destroy.
```

执行 Import Plan：

```bash
tofu apply plans/import.tfplan
tofu state list
tofu output
```

## 第二次 Apply：Delete

```bash
tofu plan -destroy -out=plans/destroy.tfplan
tofu show -no-color plans/destroy.tfplan
```

必须确认：

```text
Plan: 0 to add, 0 to change, 1 to destroy.
```

执行删除：

```bash
tofu apply plans/destroy.tfplan
tofu state list
```

## 取消删除

如果 Import 后决定保留 ACL，可解除 State 绑定：

```bash
tofu state rm volcenginecc_vpc_network_acl.target
```

普通 Plan 会根据 Import Block 再次准备导入该 ACL；Destroy Plan 不会重新导入。
