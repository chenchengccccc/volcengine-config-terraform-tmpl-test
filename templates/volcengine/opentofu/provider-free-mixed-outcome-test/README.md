# Provider-free mixed-outcome test

该模板用于验证同一 Config 修正任务中部分 exec 成功、部分 exec 失败的聚合行为，不创建云资源。

- `marker != rejected_marker`：部署成功；
- `marker == rejected_marker`：OpenTofu precondition 失败。

模板只使用 OpenTofu 内置的 `terraform_data`，不访问 Provider Registry。
