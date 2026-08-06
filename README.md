# 多云 IaC 本地 QA 实验库

模板按云厂商和执行引擎分根目录：

    terraformcc-qa-lab/
    ├── .credentials.env
    ├── .credentials.env.example
    ├── terraformrc
    └── templates/
        ├── volcengine/
        │   ├── terraformcc/             # Terraform 1.5.7
        │   │   ├── eni-add-security-group/
        │   │   ├── vpc-flow-log-to-tls/
        │   │   ├── delete-unassociated-network-acl/
        │   │   └── split-iam-user-group/
        │   └── opentofu/                # OpenTofu 1.11.8
        │       ├── eni-add-security-group/
        │       ├── eni-add-security-group-cn-shanghai/ # Provider 固定上海地域
        │       ├── vpc-flow-log-to-tls/
        │       ├── delete-unassociated-network-acl/
        │       └── split-iam-user-group/
        └── aws/
            └── cloudformation/
                ├── vpc-flow-log-to-cloudwatch/
                ├── eni-add-security-group/
                ├── delete-unassociated-network-acl/
                └── split-iam-user-group/

每个场景都有自己的 README。火山引擎 Terraform 和 OpenTofu 案例分别使用独立 State；
AWS 示例各自使用独立 CloudFormation Stack。

## 场景和费用

| 场景 | 火山引擎 | AWS CloudFormation | AWS 测试费用 |
|---|---|---|---|
| 为已有 ENI 追加安全组 | 已提供 | 已提供，先 Import 已有 ENI | 不创建 EC2、NAT Gateway 或公网 IPv4，通常无直接资源费用。 |
| 删除已有的未关联 Network ACL | 已提供 | 已提供，先 Import 已有 ACL | Network ACL 本身不额外收费。 |
| 拆分已有 IAM 用户组 | 已提供 | 已提供静态示例，先 Import 已有组 | IAM 不额外收费。 |
| 为已有 VPC 创建流日志 | 已提供 | 已提供，纯 CreateStack，不 Import VPC | CloudWatch Logs 写入和存储收费，不属于免费实验。 |

CloudFormation 对 AWS::* 资源类型本身不额外收费，但模板创建的 AWS 资源仍按各服务
价格计费。

## 火山引擎 TerraformCC

进入具体场景：

    cd templates/volcengine/terraformcc/eni-add-security-group

每次打开新终端，加载火山引擎凭证：

    source ../../../../.credentials.env

业务参数继续使用 TF_VAR_* 环境变量。例如：

    export TF_VAR_region="cn-beijing"
    export TF_VAR_network_interface_id="eni-xxxxxxxxxxxxxxxxxxxxxxxxx"

    terraform init
    terraform validate

是否需要 Import、Plan 预期结果和清理顺序，以场景 README 为准。

## 火山引擎 OpenTofu 1.11.8

OpenTofu 版本用于对比配置式 Import。进入对应场景：

    cd templates/volcengine/opentofu/eni-add-security-group
    source ../../../../.credentials.env

    export TF_VAR_region="cn-beijing"
    export TF_VAR_network_interface_id="eni-xxxxxxxxxxxxxxxxxxxxxxxxx"

    tofu init
    tofu validate

ENI 和 IAM 场景不再执行独立的 `tofu import`；Import 会进入正常 Plan/Apply。Network ACL
删除仍然需要一次 Import Apply 和一次 Destroy Apply。详细对比见
`templates/volcengine/opentofu/README.md`。

托管平台不能动态设置 Region 时，可改用
`templates/volcengine/opentofu/eni-add-security-group-cn-shanghai/`。该模板在
`provider.tf` 中固定 `cn-shanghai`，只需传入 `TF_VAR_network_interface_id`。

## AWS CloudFormation

先确认 AWS CLI 登录身份：

    aws sts get-caller-identity

再进入一个场景：

    cd templates/aws/cloudformation/delete-unassociated-network-acl

每个 AWS 场景 README 都给出了原生 AWS CLI 和 CloudFormation 命令，不保存 AWS
AccessKey，也不共享 Stack。纯新增资源的示例直接 CreateStack；涉及修改或删除已有资源的
示例从 Import 开始，不会先用 CloudFormation 创建旧资源。每个修正最多执行两次 Stack
操作；README 中的 rollback 属于可选的 QA 清理，不计入修正流程。

## 添加模板

火山引擎 TerraformCC：

    templates/volcengine/terraformcc/<case>/

火山引擎 OpenTofu：

    templates/volcengine/opentofu/<case>/

AWS CloudFormation：

    templates/aws/cloudformation/<case>/

真实凭证、Terraform State、Plan、.terraform 和真实 terraform.tfvars 均禁止提交。
