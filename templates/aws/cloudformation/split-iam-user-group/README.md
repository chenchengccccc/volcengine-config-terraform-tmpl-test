# AWS CloudFormation：两步拆分已有 IAM 用户组

这个实验只有两次 Stack 操作：

    第一步：Import 已有 Group + 组内所有 User
                         ↓
    第二步：创建两个新组 + 修改所有 User.Groups + 删除旧组

第二次是一次普通 `UpdateStack`。CloudFormation 会先创建两个新组，再把已有用户从旧组
迁移到两个新组，最后在更新清理阶段删除旧组。

示例要求已有测试组：

- 至少包含一个用户；
- 恰好关联两个 Managed Policy；
- 没有 Inline Policy；
- 组内用户当前只属于这个旧组；
- 组内用户是专用测试用户：使用默认 Path，且没有登录密码、直接挂载的 Policy、
  Permissions Boundary 或 Tag；
- 用户名只包含英文字母和数字。

这些限制保证导入模板与已有 User 的当前配置一致，并让模板能用 `Fn::ForEach` 根据
用户名生成逻辑资源，把 `Groups` 从 `[旧组]` 安全地改为 `[新组 A, 新组 B]`。

## 费用和安全

CloudFormation 和 IAM 不额外收费。第二步会删除指定的旧用户组，只能在测试账号和测试
用户组上执行。

## 1. 读取已有用户组

IAM 是全局服务，但 CloudFormation Stack 仍创建在指定地域。

    cd templates/aws/cloudformation/split-iam-user-group

    export QA_AWS_REGION="us-east-1"
    export QA_STACK_NAME="qa-cfn-split-existing-iam-group"
    export QA_LEGACY_GROUP_NAME="existing-test-group"
    export QA_GROUP_A_NAME="${QA_LEGACY_GROUP_NAME}-policy-a"
    export QA_GROUP_B_NAME="${QA_LEGACY_GROUP_NAME}-policy-b"

    aws sts get-caller-identity

确认旧组没有 Inline Policy：

    aws iam list-group-policies \
      --group-name "$QA_LEGACY_GROUP_NAME"

预期 `PolicyNames=[]`。

读取旧组的 Path、两个 Managed Policy 和全部用户：

    export QA_LEGACY_GROUP_PATH="$(
      aws iam get-group \
        --group-name "$QA_LEGACY_GROUP_NAME" \
        --query 'Group.Path' \
        --output text
    )"

    export QA_POLICY_A_ARN="$(
      aws iam list-attached-group-policies \
        --group-name "$QA_LEGACY_GROUP_NAME" \
        --query 'AttachedPolicies[0].PolicyArn' \
        --output text
    )"

    export QA_POLICY_B_ARN="$(
      aws iam list-attached-group-policies \
        --group-name "$QA_LEGACY_GROUP_NAME" \
        --query 'AttachedPolicies[1].PolicyArn' \
        --output text
    )"

    export QA_EXISTING_USER_NAMES="$(
      aws iam get-group \
        --group-name "$QA_LEGACY_GROUP_NAME" \
        --query \"join(',',Users[].UserName)\" \
        --output text
    )"

确认 Managed Policy 数量正好为 2，并记录现有成员：

    aws iam list-attached-group-policies \
      --group-name "$QA_LEGACY_GROUP_NAME"

    aws iam get-group \
      --group-name "$QA_LEGACY_GROUP_NAME" \
      --query 'Users[].UserName'

检查用户名格式：

    [[ "$QA_EXISTING_USER_NAMES" =~ '^[A-Za-z0-9]+(,[A-Za-z0-9]+)*$' ]]

检查每个用户当前只属于旧组：

    printf '%s\n' "$QA_EXISTING_USER_NAMES" \
      | tr ',' '\n' \
      | while IFS= read -r user_name; do
          aws iam list-groups-for-user \
            --user-name "$user_name" \
            --query 'Groups[].GroupName'
        done

## 2. 第一步：Import 旧组和所有已有用户

`Fn::ForEach` 会为每个用户名生成一个 `AWS::IAM::User` 资源。下面的 `jq` 同步生成
CloudFormation Import 所需的资源标识列表：

    export QA_RESOURCES_TO_IMPORT="$(
      jq -cn \
        --arg group_name "$QA_LEGACY_GROUP_NAME" \
        --arg user_names "$QA_EXISTING_USER_NAMES" '
          [{
            ResourceType: "AWS::IAM::Group",
            LogicalResourceId: "LegacyGroup",
            ResourceIdentifier: {GroupName: $group_name}
          }] + (
            $user_names
            | split(",")
            | map({
                ResourceType: "AWS::IAM::User",
                LogicalResourceId: ("ExistingUser" + .),
                ResourceIdentifier: {UserName: .}
              })
          )
        '
    )"

    export QA_IMPORT_PARAMETERS="$(
      jq -cn \
        --arg group_name "$QA_LEGACY_GROUP_NAME" \
        --arg group_path "$QA_LEGACY_GROUP_PATH" \
        --arg policy_a "$QA_POLICY_A_ARN" \
        --arg policy_b "$QA_POLICY_B_ARN" \
        --arg user_names "$QA_EXISTING_USER_NAMES" '[
          {ParameterKey: "LegacyGroupName", ParameterValue: $group_name},
          {ParameterKey: "LegacyGroupPath", ParameterValue: $group_path},
          {ParameterKey: "PolicyAArn", ParameterValue: $policy_a},
          {ParameterKey: "PolicyBArn", ParameterValue: $policy_b},
          {ParameterKey: "ExistingUserNames", ParameterValue: $user_names}
        ]'
    )"

    aws cloudformation create-change-set \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME" \
      --change-set-name import-existing-iam-group-and-users \
      --change-set-type IMPORT \
      --template-body file://01-import-existing-group.yaml \
      --parameters "$QA_IMPORT_PARAMETERS" \
      --resources-to-import "$QA_RESOURCES_TO_IMPORT" \
      --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND

    aws cloudformation wait change-set-create-complete \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME" \
      --change-set-name import-existing-iam-group-and-users

    aws cloudformation execute-change-set \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME" \
      --change-set-name import-existing-iam-group-and-users

    aws cloudformation wait stack-import-complete \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME"

## 3. 第二步：创建新组、迁移用户并删除旧组

这一步只执行一次 `UpdateStack`：

    aws cloudformation update-stack \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME" \
      --template-body file://02-split-and-delete-old-group.yaml \
      --parameters \
        ParameterKey=LegacyGroupPath,UsePreviousValue=true \
        ParameterKey=PolicyAArn,UsePreviousValue=true \
        ParameterKey=PolicyBArn,UsePreviousValue=true \
        ParameterKey=ExistingUserNames,UsePreviousValue=true \
        "ParameterKey=GroupAName,ParameterValue=$QA_GROUP_A_NAME" \
        "ParameterKey=GroupBName,ParameterValue=$QA_GROUP_B_NAME" \
      --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND

    aws cloudformation wait stack-update-complete \
      --region "$QA_AWS_REGION" \
      --stack-name "$QA_STACK_NAME"

验证旧组已经删除：

    aws iam get-group \
      --group-name "$QA_LEGACY_GROUP_NAME"

预期返回 `NoSuchEntity`。

验证两个新组包含原来的所有用户：

    aws iam get-group \
      --group-name "$QA_GROUP_A_NAME" \
      --query 'Users[].UserName'

    aws iam get-group \
      --group-name "$QA_GROUP_B_NAME" \
      --query 'Users[].UserName'

Stack 保留最终修正状态，不需要第三次 Update。若要撤销实验，应单独设计反向迁移，不属于
这次两步修正流程。
