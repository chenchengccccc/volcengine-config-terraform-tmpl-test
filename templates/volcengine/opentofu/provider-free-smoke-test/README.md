# Provider-free smoke test

该模板只用于验证 Config 与 Infra Manager 的 Deploy 成功链路，不创建云资源。

```text
Config evaluation
  -> Create remediation task
  -> GetContentUrl
  -> CreateStack
  -> DeployStack
  -> 等待 Stack 成功
  -> ListStackEvents
  -> DeleteStack(RetainResources=true)
```

模板使用 OpenTofu 内置的 `terraform_data`，因此不访问 Provider Registry。
