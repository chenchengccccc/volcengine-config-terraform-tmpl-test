# 为现有 ENI 创建并追加安全组

## 目标

1. 读取现有非托管辅助网卡。
2. 在同一 VPC 和 Project 中创建实验安全组。
3. 保留 ENI 原安全组，并追加新安全组。

资源变化：

```text
执行前
VPC
├── 现有安全组 sg-original
└── 现有 ENI（不由本模板创建）
    └── security_group_ids = {sg-original}

                    Terraform Apply
                           │
              ┌────────────┴────────────┐
              │                         │
      CREATE 新安全组 sg-new     MODIFY 现有 ENI
                                  追加 sg-new
              │                         │
              └────────────┬────────────┘
                           ▼
执行后
VPC
├── 现有安全组 sg-original
├── 新安全组 sg-new（Terraform 创建并管理）
└── 现有 ENI（通过 Import 纳入管理）
    └── security_group_ids = {sg-original, sg-new}
```

预期计划：

```text
Plan: 1 to add, 1 to change, 0 to destroy.
```

## 进入目录并加载环境

```bash
cd templates/volcengine/terraformcc/eni-add-security-group
source ../../../../.credentials.env

export TF_VAR_region="cn-beijing"
export TF_VAR_network_interface_id="eni-xxxxxxxxxxxxxxxxxxxxxxxxx"
```

Terraform 自动把 `TF_VAR_<变量名>` 映射到同名输入变量。每次新开终端需要重新加载
凭证并设置这两个模板参数。

## 初始化

```bash
terraform init
terraform validate
```

模板不声明 Backend。本地执行时 Terraform 默认将资源状态保存在：

```text
terraform.tfstate
```

托管平台执行时，由平台注入 Backend 并持久化 State。

## 首次 Import

先确认尚未创建资源 state：

```bash
terraform state list
```

首次初始化后，因为 `terraform.tfstate` 尚未生成，此命令会提示
`No state file was found`。这是预期的初始状态；import 成功后 state 文件才会创建。

然后把现有 ENI 绑定到 managed resource：

```bash
terraform import \
  volcenginecc_vpc_eni.target \
  "$TF_VAR_network_interface_id"
```

验证 state：

```bash
terraform state list
```

预期出现：

```text
data.volcenginecc_vpc_eni.target
volcenginecc_vpc_eni.target
```

Import 只修改本地 state，不修改云上 ENI。同一份 state 只需要 import 一次。

## Plan

```bash
terraform plan -out=plans/apply.tfplan
terraform show -no-color plans/apply.tfplan
```

确认：

```text
Plan: 1 to add, 1 to change, 0 to destroy.
```

## Apply

```bash
terraform apply plans/apply.tfplan
terraform output
```

再次执行：

```bash
terraform plan
```

预期结果为 `No changes.`。

## 清理

第一步，解除实验安全组与 ENI 的关联：

```bash
export TF_VAR_attach_new_security_group=false

terraform plan \
  -out=plans/detach.tfplan
terraform show -no-color plans/detach.tfplan
terraform apply plans/detach.tfplan
```

第二步，只解除 Terraform 对原有 ENI 的管理，不删除云上 ENI：

```bash
terraform state rm volcenginecc_vpc_eni.target
```

第三步，删除 Terraform 创建的实验安全组：

```bash
terraform destroy
```

最后：

```bash
terraform state list
```

结果应为空。执行 `state rm` 后不要再执行普通 plan，否则 Terraform 会把缺失的
ENI 当作待创建资源。
