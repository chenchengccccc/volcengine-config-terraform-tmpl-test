# OpenTofu：将长期 AccessKey 迁移为 IAM Role

## 实验目标

使用一个资源栈、两个 Apply 验证跨资源类型的分阶段迁移：

```text
第一次 Apply：Import 测试 AccessKey + Create IAM Role

测试 IAM 用户 ──直接授权策略──┐
                             ├──复制──> 新 IAM Role（保留）
测试 AccessKey ──Import──────┘
       │
       └──仍然启用，留出业务切换和验证窗口

第二次 Apply：Delete 测试 AccessKey

新 IAM Role    ──保留
测试 AccessKey ──Delete
```

AccessKey 和 IAM Role 是不同资源，不能用 `create_before_destroy` 表示这个迁移。真正的业务
场景还需要在两次 Apply 之间把调用方切换为 `AssumeRole`；本模板只负责云资源部分。

## 安全要求

- 只能使用专门创建的测试 IAM 用户和测试 AccessKey；
- 禁止填写 OpenTofu/Infra Manager 当前使用的 AccessKey；
- 测试用户不能加入用户组，并且至少直接关联一个策略；
- 模板只复制测试用户的直接授权策略，不复制通过用户组继承的权限；
- 第二次 Apply 会永久删除指定 AccessKey，Secret 无法恢复。

IAM 用户、AccessKey 和 Role 不收费。

## 准备测试资源

在 IAM 控制台创建专用测试用户，例如 `qa-ak-migration`：

1. 不允许控制台登录；
2. 不加入任何用户组；
3. 直接关联一个低权限策略，例如只读策略；
4. 创建一把测试 AccessKey，并记录 AccessKey ID；
5. 不要在任何真实业务中使用这把测试 AccessKey。

Role 的信任策略允许当前账号内的身份扮演该 Role。实际调用 `AssumeRole` 的 IAM 身份仍需
具备 `sts:AssumeRole` 权限；本实验不自动修改调用方权限。

## 本地初始化

```bash
cd templates/volcengine/opentofu/migrate-access-key-to-role
source ../../../../.credentials.env

export TF_VAR_user_name="qa-ak-migration"
export TF_VAR_access_key_id="替换为测试AccessKeyID"
export TF_VAR_delete_legacy_access_key=false

tofu init
tofu validate
tofu state list
```

`role_name` 可以不传，模板会根据 `user_name` 生成稳定名称。需要指定时使用：

```bash
export TF_VAR_role_name="qa-ak-migration-role"
```

## 第一次 Apply：Import + Create

```bash
tofu plan -out=plans/prepare.tfplan
tofu show -no-color plans/prepare.tfplan
```

必须确认计划包含：

```text
volcenginecc_iam_accesskey.legacy["target"]：Import，保持 active
volcenginecc_iam_role.replacement：Create
terraform_data.migration_context：Create，记录本次迁移对象

Plan: 1 to import, 2 to add, 0 to change, 0 to destroy.
```

执行：

```bash
tofu apply plans/prepare.tfplan
tofu output migration_summary
```

此时旧 AccessKey 仍然存在，新 Role 已经创建。

## 第二次 Apply：Delete

第二次必须继续使用同一个目录和同一份 State。本地实验只修改阶段变量：

```bash
export TF_VAR_delete_legacy_access_key=true

tofu plan -out=plans/delete-key.tfplan
tofu show -no-color plans/delete-key.tfplan
```

必须确认计划只删除测试 AccessKey，不替换或删除 Role：

```text
volcenginecc_iam_accesskey.legacy["target"]：Delete
volcenginecc_iam_role.replacement：No changes

Plan: 0 to add, 0 to change, 1 to destroy.
```

`terraform_data.migration_context` 会保存第一次 Apply 的对象标识。直接从
`delete_legacy_access_key=true` 开始，或者第二次更换用户、AccessKey、Role 名称，Plan 都会失败。

确认 AccessKey ID 后执行：

```bash
tofu apply plans/delete-key.tfplan
tofu output migration_summary
```

## Infra Manager 调用方式

两次执行必须使用同一个 `StackName`。第一次创建资源栈，第二次更新该资源栈；模板地址保持
不变，只修改 `delete_legacy_access_key`：

```text
CreateStack
  user_name                   = qa-ak-migration
  access_key_id               = <测试 AccessKey ID>
  delete_legacy_access_key    = false

UpdateStack（同一个 StackName）
  user_name                   = qa-ak-migration
  access_key_id               = <同一个测试 AccessKey ID>
  delete_legacy_access_key    = true
```

如果后端使用 `deploy := [{...}, {...}]` 表示顺序执行，两个元素必须共享同一个资源栈和 State；
第二个元素不能创建新的资源栈。

## 实验清理

完成第二次 Apply 后，State 中只剩新 Role 和迁移上下文。删除它们：

```bash
tofu destroy
```

测试用户由实验前置步骤创建，不在本资源栈中，需要在 IAM 控制台单独删除。

如果只执行了第一次 Apply，不要直接 `tofu destroy`，否则会同时删除测试 AccessKey。应先从
State 中解除 AccessKey 管理，再删除 Role：

```bash
tofu state rm 'volcenginecc_iam_accesskey.legacy["target"]'
tofu destroy
```
