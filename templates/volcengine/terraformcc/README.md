# 火山引擎 TerraformCC QA 模板

每个子目录都是独立 Terraform root module，并保存自己的 State 和 Plan：

- eni-add-security-group
- vpc-flow-log-to-tls
- delete-unassociated-network-acl
- split-iam-user-group

进入场景目录后加载根目录凭证：

    source ../../../../.credentials.env

使用 `volcenginecc` Provider 的模板默认连接 `cn-guilin-boe` 和 BOE CloudControl endpoint；
如需验证其他环境，可通过 `TF_VAR_region` 和 `TF_VAR_cloud_control_endpoint` 显式覆盖。

具体参数、Import、Plan 和清理步骤以场景 README 为准。
