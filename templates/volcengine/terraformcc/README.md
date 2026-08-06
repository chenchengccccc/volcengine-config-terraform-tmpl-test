# 火山引擎 TerraformCC QA 模板

每个子目录都是独立 Terraform root module，并保存自己的 State 和 Plan：

- eni-add-security-group
- vpc-flow-log-to-tls
- delete-unassociated-network-acl
- split-iam-user-group

进入场景目录后加载根目录凭证：

    source ../../../../.credentials.env

具体参数、Import、Plan 和清理步骤以场景 README 为准。
