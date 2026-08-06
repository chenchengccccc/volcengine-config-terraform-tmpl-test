# OpenTofu：为上海地域的现有 ENI 创建并追加安全组

## 目标

本模板在文件中固定：

```hcl
provider "volcenginecc" {
  region = "cn-shanghai"
}
```

使用者只需提供上海地域的现有 ENI ID。一次 Plan/Apply 完成：

```text
cn-shanghai 已有 ENI
          │
          ├── IMPORT：纳入平台托管 State
          ├── CREATE：在 ENI 所属 VPC 创建新安全组
          └── MODIFY：当前安全组集合 ∪ 新安全组
```

预期首次计划：

```text
Plan: 1 to import, 1 to add, 1 to change, 0 to destroy.
```

## 本地验证

```bash
cd templates/volcengine/opentofu/eni-add-security-group-cn-shanghai
source ../../../../.credentials.env

export TF_VAR_network_interface_id="eni-xxxxxxxxxxxxxxxxxxxxxxxxx"

tofu init
tofu validate
tofu plan -out=plans/apply.tfplan
tofu show -no-color plans/apply.tfplan
```

不要设置 `TF_VAR_region`，也不要额外运行 `tofu import`。

## 托管平台参数

平台选择当前目录作为模板根目录，只需注入：

```text
TF_VAR_network_interface_id=eni-xxxxxxxxxxxxxxxxxxxxxxxxx
```

平台生成 Backend 并持久化 State；本模板不声明 Backend。执行前确认 ENI 确实属于
`cn-shanghai`，否则 Provider 无法读取目标资源。

必须确认 Plan 包含：

```text
volcenginecc_vpc_eni.target                         Import + Update
volcenginecc_vpc_security_group.remediation        Create
```

本模板只执行修正：创建安全组并关联 ENI，不包含解除关联或删除资源的清理流程。
