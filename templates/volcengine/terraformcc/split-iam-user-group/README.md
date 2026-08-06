# 按 Policy 拆分 IAM 用户组

## 目标

给定一个已有 IAM 用户组，将它关联的 N 个 Policy 拆成 N 个独立用户组：

- 每个最终用户组只关联一个原 Policy；
- 每个最终用户组都包含原用户组的全部 User；
- 使用者只填写旧用户组名；
- 创建 N 个新用户组后删除旧用户组。

```text
旧组：User A、User B
      Policy 1、Policy 2、Policy 3
                    │
                    ▼
新组 1：User A、User B ── Policy 1
新组 2：User A、User B ── Policy 2
新组 3：User A、User B ── Policy 3
旧组：删除
```

旧组先被 Import 到 `volcenginecc_iam_group.primary`，而代码中的同一资源地址使用新的
稳定组名。`create_before_destroy` 要求 Terraform 在发生替换时先创建新的 primary 组，
再删除 Import 进来的旧组。其余 N-1 个组通过 `depends_on` 更早完成创建和关联。

这是一次性迁移模板。旧组删除后，读取旧组的数据源将无法在下一次 Plan 中刷新，
因此它不适合作为长期反复执行的托管栈。

## Terraform 如何决定拆分结果

模板自动读取旧组：

1. 复制旧组的全部 `users`；
2. 按 `policy_type|policy_name` 对全部 Policy 排序；
3. 第一个 Policy 创建 `primary` 替代组；
4. 其余每个 Policy 分别创建一个名称稳定的新组；
5. 所有最终组都使用同一份原用户列表。

Plan 文件会固化本次读取到的用户和 Policy。Apply 必须使用保存的 Plan 文件，不能在
两者之间重新生成 Plan。

## 前置条件

- 旧用户组已经存在；
- 旧组至少包含一个 User；
- 旧组至少关联两个 Policy；
- 旧组中的 Policy 都是全局授权，不包含按 IAM Project 授权；
- 执行凭证拥有 IAM Group 的读取、创建、更新和授权权限。

IAM 是免费服务，本模板不会创建收费资源，也不会创建、更新或删除 IAM User。

## 指定旧用户组

加载执行环境后，只需设置旧用户组名：

```bash
source ../../../../.credentials.env
export TF_VAR_old_group_name="qa-legacy-developers"
```

Terraform 会把 `TF_VAR_old_group_name` 作为 `old_group_name` 变量，同时 Import 命令也
直接复用这个值，不需要在两个文件或命令中重复填写。IAM 是全局服务，模板不接收地域
参数；`provider.tf` 中的 `cn-beijing` 只用于选择 Provider 请求端点。

## 初始化和 Plan

```bash
cd templates/volcengine/terraformcc/split-iam-user-group
source ../../../../.credentials.env
export TF_VAR_old_group_name="qa-legacy-developers"

terraform init
terraform validate
terraform state list
terraform import volcenginecc_iam_group.primary "$TF_VAR_old_group_name"
terraform plan -out=plans/apply.tfplan
terraform show -no-color plans/apply.tfplan
```

TerraformCC 0.0.57 将 `user_group_name` 定义为强制替换属性。Plan 必须显示：

```text
user_group_name = "旧组" -> "新组" # forces replacement
volcenginecc_iam_group.primary: +/- create replacement and then destroy
```

不需要额外传入 `-replace`。`create_before_destroy` 将默认的 `-/+` 调整为 `+/-`。

Terraform 1.5.7 的 Import 块不允许在 `id` 中引用变量，所以这里保留原生
`terraform import`。旧组名仍然只在 `TF_VAR_old_group_name` 中设置一次。

如果旧组有 N 个 Policy，Plan 必须确认包含：

```text
N-1 个 volcenginecc_iam_group.split Create
1 个 volcenginecc_iam_group.primary Create replacement
1 个 import 进来的旧组 Destroy
```

由于配置了 `create_before_destroy`，Plan 中 primary 的符号应为 `+/-`，不能是 `-/+`。

## Apply

检查 Plan 后执行：

```bash
terraform apply plans/apply.tfplan
terraform output
```

输出中的：

```text
original_policy_count == final_group_count
```

表示 N 个 Policy 已对应 N 个单策略组。

## 权限变化

用户拆分前后的有效权限集合不变：

- 拆分前：用户通过一个组获得 N 个 Policy；
- 拆分后：用户通过 N 个组分别获得同样的 N 个 Policy。

N 个新组全部创建成功后，Terraform 才删除旧组，因此不会先移除旧权限。

不要在 Apply 后再次执行普通 Plan：数据源仍以旧组名读取源数据，而旧组已经删除。
生产化时应在迁移成功后把新组快照固化为长期模板，或由上层编排切换到不再读取旧组
的第二版模板。

## 清理警告

不要在真实业务组上直接实验，也不要执行 `terraform destroy`。Apply 后 State 中的
`volcenginecc_iam_group.primary` 已经指向新的替代组，Destroy 会删除全部新组。

QA 如果需要回滚，应先重建旧组并按照 `source_snapshot` 恢复全部用户和 Policy，再删除
新建的拆分组。不要通过删除 IAM User 清理实验。
