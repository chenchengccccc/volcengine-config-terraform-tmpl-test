# 火山引擎 OpenTofu 1.11.8  模板

本目录使用 OpenTofu 1.11.8 和 `volcenginecc` Provider 0.0.57，与  
`../terraformcc/` 下的 Terraform 1.5.7 版本并列，便于比较执行流程。

```text
templates/volcengine/
├── terraformcc/   Terraform 1.5.7 + TerraformCC Provider
└── opentofu/      OpenTofu 1.11.8 + 同一个 TerraformCC Provider
```

## Terraform 和 OpenTofu 的定位

Terraform 和 OpenTofu 是同一层的两个 IaC 核心引擎。OpenTofu 不是 Terraform 的  
上层编排产品，也不是一种 Provider；使用 OpenTofu，就是在相同位置用它替换 Terraform。

|      | Terraform                                                                       | OpenTofu                                                   |
| ---- | ------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| 产品归属 | HashiCorp 主导的 Terraform 产品及生态                                                   | Linux Foundation 托管、社区治理的开源项目                              |
| 产品定位 | IaC 核心引擎和 CLI                                                                   | 兼容 Terraform 的 IaC 核心引擎和 CLI                               |
| 两者关系 | 原始 Terraform 实现                                                                 | 从 Terraform 分叉而来，可作为其直接替代品，并独立演进                           |
| 分叉原因 | 2023 年，HashiCorp 将 Terraform 后续版本从 MPL 2.0 改为 BSL 1.1，限制将其用于与 HashiCorp 竞争的托管产品 | 社区希望保留一个厂商中立、社区治理、可自由构建和托管的开源实现，因此从最后一个 MPL 版本分叉出 OpenTofu |
| 所处层级 | 模板与 Provider 之间                                                                 | 与 Terraform 完全相同                                           |

## 流程差异

| 场景                  | Terraform 1.5.7         | OpenTofu 1.11.8                                  |
| ------------------- | ----------------------- | ------------------------------------------------ |
| ENI 追加安全组           | CLI Import，再 Plan/Apply | Import、Create、Modify 在同一个 Plan/Apply             |
| 拆分 IAM 用户组          | CLI Import，再 Plan/Apply | Import、Create replacement、Delete 在同一个 Plan/Apply |
| AccessKey 迁移到 IAM Role | 未提供此实验模板            | 同一资源栈执行两次 Apply：Import + Create，再 Delete       |
| 删除未关联 Network ACL   | CLI Import，再 Destroy    | Import Plan/Apply，再 Destroy Plan/Apply           |
| VPC Flow Log 投递 TLS | 一次 Plan/Apply           | 一次 Plan/Apply，无变化                                |

OpenTofu 1.11.8 的 `import.id` 仍不能直接引用变量，因此需要单元素 `for_each`：

```hcl
import {
  for_each = {
    target = var.existing_resource_id
  }

  to = volcenginecc_example.target
  id = each.value
}
```

Import Block 是幂等声明：资源地址已经存在于 State 时，后续 Plan 不会再次 Import。

## 使用要求

- 固定使用 OpenTofu 1.11.8，不要用 Terraform 1.5.7 执行本目录。
- 模板不声明 Backend；本地执行默认在案例目录保存 `terraform.tfstate`，托管执行由平台注入 Backend。
- 第一次 `tofu init` 会生成 OpenTofu 版本的 `.terraform.lock.hcl`。
- Provider、资源 Schema 和云 API 行为没有变化；简化来自 OpenTofu 的配置式 Import。

进入具体案例后执行：

```bash
source ../../../../.credentials.env
tofu init
tofu validate
```

业务参数仍然使用 `TF_VAR_*` 环境变量。所有使用 `volcenginecc` Provider 的模板默认连接
`cn-guilin-boe` 和 BOE CloudControl endpoint；如需验证其他环境，可通过
`TF_VAR_region` 和 `TF_VAR_cloud_control_endpoint` 显式覆盖。具体 Plan 预期和清理步骤见各案例 README。
