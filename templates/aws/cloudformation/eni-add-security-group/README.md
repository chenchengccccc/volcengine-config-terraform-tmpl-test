# AWS CloudFormation：为已有 ENI 追加安全组

这个实验不创建旧 VPC、旧子网或旧 ENI。起点是账号中已经存在的 ENI：

    已有 ENI -> 原安全组集合
          ↓ Import
    CloudFormation 接管已有 ENI
          ↓ UpdateStack
    新建安全组并更新 ENI.GroupSet
          ↓
    已有 ENI -> 原安全组集合 + 新安全组

`AWS::EC2::NetworkInterface` 支持 Import，导入标识为 `Id`。Import 只接管 ENI；第二次
Stack 操作才创建新安全组并修改 ENI。

## 费用和安全

CloudFormation、ENI 和安全组通常没有直接资源费用。本实验不会创建 EC2、NAT Gateway
或公网 IPv4。

请选择自己创建、允许修改的非关键 ENI。不要使用负载均衡、NAT Gateway 等服务托管的
requester-managed ENI。

## 1. 指定已有 ENI

    cd templates/aws/cloudformation/eni-add-security-group

    export QA_AWS_REGION="us-east-1"
    export QA_STACK_NAME="qa-cfn-existing-eni-add-sg"
    export QA_ENI_ID="eni-xxxxxxxxxxxxxxxxx"
    export QA_NAME_PREFIX="qa-cfn-existing-eni"

    aws sts get-caller-identity

读取已有 ENI 当前配置：

    export QA_SUBNET_ID="$(
      aws ec2 describe-network-interfaces \
        --region "$QA_AWS_REGION" \
        --network-interface-ids "$QA_ENI_ID" \
        --query 'NetworkInterfaces[0].SubnetId' \
        --output text
    )"

    export QA_VPC_ID="$(
      aws ec2 describe-network-interfaces \
        --region "$QA_AWS_REGION" \
        --network-interface-ids "$QA_ENI_ID" \
        --query 'NetworkInterfaces[0].VpcId' \
        --output text
    )"

    export QA_EXISTING_SECURITY_GROUP_IDS="$(
      aws ec2 describe-network-interfaces \
        --region "$QA_AWS_REGION" \
        --network-interface-ids "$QA_ENI_ID" \
        --query \"join(',',NetworkInterfaces[0].Groups[].GroupId)\" \
        --output text
    )"

检查目标不是 requester-managed ENI，并记录原安全组：

    aws ec2 describe-network-interfaces \
      --region "$QA_AWS_REGION" \
      --network-interface-ids "$QA_ENI_ID" \
      --query 'NetworkInterfaces[0].{Id:NetworkInterfaceId,RequesterManaged:RequesterManaged,Status:Status,SubnetId:SubnetId,VpcId:VpcId,Groups:Groups}'

只有 `RequesterManaged=false` 时才继续。

## 2. Import 已有 ENI

第一份模板完整保留当前 `GroupSet`，不会在 Import 时追加安全组：

    aws cloudformation create-change-set \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME" \
      --change-set-name import-existing-eni \
      --change-set-type IMPORT \
      --template-body file://01-import-existing-eni.yaml \
      --parameters "[{\"ParameterKey\":\"ExistingSubnetId\",\"ParameterValue\":\"$QA_SUBNET_ID\"},{\"ParameterKey\":\"ExistingSecurityGroupIds\",\"ParameterValue\":\"$QA_EXISTING_SECURITY_GROUP_IDS\"}]" \
      --resources-to-import "[{\"ResourceType\":\"AWS::EC2::NetworkInterface\",\"LogicalResourceId\":\"TargetNetworkInterface\",\"ResourceIdentifier\":{\"Id\":\"$QA_ENI_ID\"}}]"

    aws cloudformation wait change-set-create-complete \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME" \
      --change-set-name import-existing-eni

    aws cloudformation execute-change-set \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME" \
      --change-set-name import-existing-eni

    aws cloudformation wait stack-import-complete \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME"

Import 后再次查询 ENI，安全组集合应保持不变。

## 3. 创建安全组并修改已有 ENI

第二份模板增加 `AddedSecurityGroup`，并在 `TargetNetworkInterface.GroupSet` 中引用它。
这个引用使 CloudFormation 先创建安全组，再更新已有 ENI：

    aws cloudformation update-stack \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME" \
      --template-body file://02-add-security-group.yaml \
      --parameters \
        ParameterKey=ExistingSubnetId,UsePreviousValue=true \
        ParameterKey=ExistingSecurityGroupIds,UsePreviousValue=true \
        "ParameterKey=ExistingVpcId,ParameterValue=$QA_VPC_ID" \
        "ParameterKey=NamePrefix,ParameterValue=$QA_NAME_PREFIX"

    aws cloudformation wait stack-update-complete \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME"

验证已有 ENI 同时关联原安全组和新安全组：

    aws ec2 describe-network-interfaces \
      --region "$QA_AWS_REGION" \
      --network-interface-ids "$QA_ENI_ID" \
      --query 'NetworkInterfaces[0].Groups'

修正到这里结束，总共两次 Stack 操作：一次 Import、一次 UpdateStack。

## 可选：撤销并清理 QA 实验

下面是测试结束后的反向操作，不属于修正步骤。不能直接删除 Stack：ENI 被设置为
`Retain`，如果仍引用新安全组，新安全组将无法删除。
先恢复 ENI 原来的安全组集合，并让 CloudFormation 删除实验创建的新安全组：

    aws cloudformation update-stack \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME" \
      --template-body file://rollback.yaml \
      --parameters \
        ParameterKey=ExistingSubnetId,UsePreviousValue=true \
        ParameterKey=ExistingSecurityGroupIds,UsePreviousValue=true

    aws cloudformation wait stack-update-complete \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME"

再删除 Stack。`DeletionPolicy: Retain` 会保留已有 ENI：

    aws cloudformation delete-stack \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME"

    aws cloudformation wait stack-delete-complete \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME"

最终确认 ENI 仍存在，且安全组集合已经恢复：

    aws ec2 describe-network-interfaces \
      --region "$QA_AWS_REGION" \
      --network-interface-ids "$QA_ENI_ID" \
      --query 'NetworkInterfaces[0].Groups'

这个流程验证的是 `Import existing → Deploy new → Modify existing`，而不是在同一个 Stack
里先创建一套旧资源。
