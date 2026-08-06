# AWS CloudFormation QA 模板

这组模板统一从账号中的已有资源开始。涉及修改或删除已有资源时，先使用
CloudFormation Import 将目标纳入 Stack；模板不会先创建一套“旧资源”。

四组修正都最多执行两次 Stack 操作：

| 场景 | 第一步 | 第二步 |
|---|---|---|
| 为已有 VPC 部署 Flow Log | 创建 Log Group、IAM Role 和 Flow Log | — |
| 为已有 ENI 追加安全组 | Import ENI | 创建安全组并更新 ENI |
| 删除已有的未关联 Network ACL | Import ACL | DeleteStack |
| 拆分已有 IAM 用户组 | Import Group 和全部 User | 创建新组、迁移 User、删除旧组 |

| 场景 | 入口 | 费用 |
|---|---|---|
| 为已有 VPC 部署 Flow Log | vpc-flow-log-to-cloudwatch/README.md | CloudWatch Logs 写入和存储收费 |
| 为已有 ENI 追加安全组 | eni-add-security-group/README.md | 通常无直接资源费用 |
| 删除已有的未关联 Network ACL | delete-unassociated-network-acl/README.md | Network ACL 不额外收费 |
| 拆分已有 IAM 用户组 | split-iam-user-group/README.md | IAM 不额外收费 |

所有命令都使用本机 AWS CLI 的登录状态，不在目录中保存 AWS AccessKey。
