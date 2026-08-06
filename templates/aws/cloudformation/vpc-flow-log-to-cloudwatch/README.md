# AWS CloudFormation：为已有 VPC 部署 Flow Log

这是一个纯 `DEPLOY` 场景。模板只读取已有 VPC 的 ID，不 Import，也不修改 VPC：

    已有 VPC
       │ ExistingVpcId
       ▼
    CreateStack
       ├── 新建 CloudWatch Logs Log Group
       ├── 新建 IAM Role
       └── 新建 VPC Flow Log
                  ├── 引用 Log Group
                  ├── 引用 IAM Role
                  └── 关联已有 VPC ID

`VpcFlowLog` 通过 `!Ref FlowLogGroup` 和 `!GetAtt FlowLogsRole.Arn` 引用前两个资源。
CloudFormation 会根据这些引用确定创建顺序，不需要手写 `DependsOn`。

这个场景对应 AWS Config 托管规则
[`VPC_FLOW_LOGS_ENABLED`](https://docs.aws.amazon.com/config/latest/developerguide/vpc-flow-logs-enabled.html)：
VPC 没有 Flow Log 时，只需要新建资源，不需要接管原 VPC。

## 费用

Flow Log 写入 CloudWatch Logs 会产生日志写入和存储费用。模板将日志保留时间设为 1 天，
但这不是免费实验；请使用低流量测试 VPC，并在验证后删除 Stack。计费说明见
[`Publish flow logs to CloudWatch Logs`](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs-cwl.html)。

## 1. 指定已有 VPC

    cd templates/aws/cloudformation/vpc-flow-log-to-cloudwatch

    export QA_AWS_REGION="us-east-1"
    export QA_STACK_NAME="qa-cfn-vpc-flow-log"
    export QA_VPC_ID="vpc-xxxxxxxxxxxxxxxxx"
    export QA_NAME_PREFIX="qa-cfn-vpc-flow-log"

    aws sts get-caller-identity

确认目标 VPC 存在：

    aws ec2 describe-vpcs \
      --region "$QA_AWS_REGION" \
      --vpc-ids "$QA_VPC_ID" \
      --query 'Vpcs[0].{VpcId:VpcId,State:State,IsDefault:IsDefault}'

## 2. 一次 CreateStack 完成修正

    aws cloudformation create-stack \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME" \
      --template-body file://01-deploy-vpc-flow-log.yaml \
      --parameters \
        "ParameterKey=ExistingVpcId,ParameterValue=$QA_VPC_ID" \
        "ParameterKey=NamePrefix,ParameterValue=$QA_NAME_PREFIX" \
      --capabilities CAPABILITY_IAM

    aws cloudformation wait stack-create-complete \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME"

查看 Stack 创建的资源：

    aws cloudformation describe-stack-resources \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME" \
      --query 'StackResources[].{LogicalId:LogicalResourceId,Type:ResourceType,PhysicalId:PhysicalResourceId,Status:ResourceStatus}'

验证已有 VPC 已关联 Flow Log：

    aws ec2 describe-flow-logs \
      --region "$QA_AWS_REGION" \
      --filter "Name=resource-id,Values=$QA_VPC_ID" \
      --query 'FlowLogs[].{FlowLogId:FlowLogId,Status:FlowLogStatus,Destination:LogDestination,TrafficType:TrafficType}'

修正到这里结束，只执行了一次 `CreateStack`。

## 清理 QA 实验

删除 Stack 会按依赖顺序删除 Flow Log、IAM Role 和 Log Group，不会删除或修改已有 VPC。
Log Group 中已经写入的测试日志也会被删除：

    aws cloudformation delete-stack \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME"

    aws cloudformation wait stack-delete-complete \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME"
