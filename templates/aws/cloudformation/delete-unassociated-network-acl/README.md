# AWS CloudFormation：删除已有的未关联 Network ACL

这个实验不创建 VPC 或 Network ACL。起点是账号中已经存在的自定义 Network ACL：

    已有且未关联子网的 Network ACL
                  ↓ Import
          CloudFormation Stack
                  ↓ DeleteStack
             删除 Network ACL

`AWS::EC2::NetworkAcl` 支持 Import，导入标识为 `Id`。模板将
`DeletionPolicy` 设置为 `Delete`，因此删除 Stack 时会删除导入的 ACL。

CloudFormation 不负责判断 ACL 是否关联子网。实验前必须确认目标不是默认 ACL，且
`Associations` 为空。

## 费用

CloudFormation 和 Network ACL 不额外收费。本实验不创建其他云资源。

## 1. 指定已有资源

    cd templates/aws/cloudformation/delete-unassociated-network-acl

    export QA_AWS_REGION="us-east-1"
    export QA_STACK_NAME="qa-cfn-delete-existing-nacl"
    export QA_NETWORK_ACL_ID="acl-xxxxxxxxxxxxxxxxx"

    aws sts get-caller-identity

从已有 ACL 读取 VPC ID：

    export QA_VPC_ID="$(
      aws ec2 describe-network-acls \
        --region "$QA_AWS_REGION" \
        --network-acl-ids "$QA_NETWORK_ACL_ID" \
        --query 'NetworkAcls[0].VpcId' \
        --output text
    )"

确认删除条件：

    aws ec2 describe-network-acls \
      --region "$QA_AWS_REGION" \
      --network-acl-ids "$QA_NETWORK_ACL_ID" \
      --query 'NetworkAcls[0].{Id:NetworkAclId,VpcId:VpcId,IsDefault:IsDefault,Associations:Associations}'

只有 `IsDefault=false` 且 `Associations=[]` 时才继续。

## 2. Import 已有 ACL

Import 只把已有 ACL 纳入 Stack，不创建或修改它：

    aws cloudformation create-change-set \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME" \
      --change-set-name import-existing-network-acl \
      --change-set-type IMPORT \
      --template-body file://01-import-existing-network-acl.yaml \
      --parameters "ParameterKey=ExistingVpcId,ParameterValue=$QA_VPC_ID" \
      --resources-to-import "[{\"ResourceType\":\"AWS::EC2::NetworkAcl\",\"LogicalResourceId\":\"TargetNetworkAcl\",\"ResourceIdentifier\":{\"Id\":\"$QA_NETWORK_ACL_ID\"}}]"

    aws cloudformation wait change-set-create-complete \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME" \
      --change-set-name import-existing-network-acl

    aws cloudformation execute-change-set \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME" \
      --change-set-name import-existing-network-acl

    aws cloudformation wait stack-import-complete \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME"

确认 Stack 管理的是指定 ACL：

    aws cloudformation describe-stack-resource \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME" \
      --logical-resource-id TargetNetworkAcl

## 3. 删除已有 ACL

删除前再次检查关联关系：

    aws ec2 describe-network-acls \
      --region "$QA_AWS_REGION" \
      --network-acl-ids "$QA_NETWORK_ACL_ID" \
      --query 'NetworkAcls[0].Associations'

确认仍为空后删除 Stack：

    aws cloudformation delete-stack \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME"

    aws cloudformation wait stack-delete-complete \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME"

验证 ACL 已不存在，预期返回 `InvalidNetworkAclID.NotFound`：

    aws ec2 describe-network-acls \
      --region "$QA_AWS_REGION" \
      --network-acl-ids "$QA_NETWORK_ACL_ID"

这个实验验证的是 CloudFormation 对已有资源的 `Import → Delete`，没有准备栈，也没有
先创建一套旧资源。
