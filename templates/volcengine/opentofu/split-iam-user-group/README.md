# OpenTofu：按 Policy 拆分 IAM 用户组

## 目标

给定一个已有 IAM 用户组，把它关联的 N 个 Policy 拆成 N 个新用户组：

```text
旧组：全部 User + Policy 1..N
                 │
                 │ 一次 Plan/Apply
                 ▼
新组 1：全部 User + Policy 1
...
新组 N：全部 User + Policy N
旧组：删除
```

`imports.tf` 把旧组 Import 到 `volcenginecc_iam_group.primary`。`main.tf` 在同一资源地址
声明新的稳定组名，因此 Provider 的强制替换属性会让同一个 Plan 同时包含 Import 和
replacement。`create_before_destroy` 保证先建新组，再删旧组。

与 Terraform 1.5.7 版本相比，不需要单独执行 CLI Import。

## 前置条件

- 旧组至少包含一个 User；
- 旧组至少关联两个全局 Policy；
- 执行凭证拥有 IAM Group 的读取、创建、更新、授权和删除权限；
- 这是一次性迁移模板，不要用于真实关键用户组的首次验证。

## 初始化并指定旧组

```bash
cd templates/volcengine/opentofu/split-iam-user-group
source ../../../../.credentials.env

export TF_VAR_old_group_name="qa-legacy-developers"

tofu init
tofu validate
tofu state list
```

IAM 是全局服务，模板不接收地域参数；`provider.tf` 中的 `cn-beijing` 只用于选择
Provider 请求端点。

不要运行 `tofu import`。

## 一次 Plan/Apply 完成迁移

```bash
tofu plan -out=plans/apply.tfplan
tofu show -no-color plans/apply.tfplan
```

必须确认：

```text
volcenginecc_iam_group.primary: Import 后执行 +/- replacement
volcenginecc_iam_group.split:   创建其余 N-1 个组

Plan: 1 to import, N to add, 0 to change, 1 to destroy.
```

`primary` 必须显示 `+/- create replacement and then destroy`，不能是 `-/+`。

执行保存的计划：

```bash
tofu apply plans/apply.tfplan
tofu output
```

输出中的 `original_policy_count == final_group_count` 表示每个原 Policy 已对应一个新组。

## 一次性限制

旧组删除后，`data.volcenginecc_iam_group.source` 无法再次刷新，因此不要在 Apply 后执行
普通 Plan。OpenTofu 1.11.8 合并了 Import 与替换，但没有消除源资源被删除后的数据源
失效问题。

QA 回滚时需要根据 `source_snapshot` 重建旧组、恢复全部 User 和 Policy，再删除拆分组。
不要执行 `tofu destroy`，它会删除全部新组。
