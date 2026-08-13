# OpenTofu：创建空 IAM 用户组

## 目标

创建一个不含用户和策略的 IAM 用户组，用于验证纯 CREATE 修正链路：

```text
Config Deploy
     ↓
Infra Manager + OpenTofu
     ↓
空 IAM 用户组
```

模板不读取、不导入也不修改已有资源。IAM 用户组不收费。

## 输入

只接收 `user_group_name`，名称必须以 `config-deploy-e2e-` 开头。

```bash
export TF_VAR_user_group_name="config-deploy-e2e-example"
```

预期 Plan：

```text
Plan: 1 to add, 0 to change, 0 to destroy.
```

本模板用于测试本期 Config Deploy 的 CreateStack、DeployStack 和保留资源 DeleteStack。
资源栈删除后，空用户组会被保留；测试结束后可从 IAM 控制台删除该空组。
