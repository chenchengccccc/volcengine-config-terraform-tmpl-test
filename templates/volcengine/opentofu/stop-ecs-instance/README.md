# OpenTofu：停止已有 ECS 实例

## 目标

通过一次 Plan/Apply 将一个已有 ECS 实例纳入当前独立 State，并把它的最终状态声明为
`STOPPED`。模板不会创建、替换或删除 ECS。

```text
已有 ECS（RUNNING 或 STOPPED）
             │
             ├── READ：读取现有配置
             ├── IMPORT：纳入当前独立 State
             └── UPDATE：status -> STOPPED
```

为避免给创建必填字段写死值，模板会从只读 data source 回填目标实例的镜像 ID、规格、
名称和可用区。主网卡与系统盘的其余配置继续由 Import 后的 State 管理，不会作为本次更新
的输入。因此正常情况下，Plan 的唯一业务变更是 `status` 和停机模式。

## 停机模式

默认不传 `stopped_mode`，因此模板只声明 `status = STOPPED`，不覆盖云侧或控制台已有的
默认停机策略。

如需固定模式，可显式指定 `KeepCharging`（保留计算资源，费用保持不变）或
`StopCharging`（回收 vCPU、GPU 和内存资源并停止计算费用）。后者下，挂载云盘、镜像和
公网 IP 等资源仍可能继续计费；再次启动时也需要重新分配计算资源。

## 初始化并指定目标

```bash
cd templates/volcengine/opentofu/stop-ecs-instance
source ../../../../.credentials.env

export TF_VAR_instance_id="i-xxxxxxxxxxxxxxxxx"

# 可选；未设置时不覆盖云侧默认策略。
# export TF_VAR_stopped_mode="KeepCharging"
# export TF_VAR_stopped_mode="StopCharging"

tofu init
tofu validate
tofu state list
```

首次执行时 State 为空是正常现象。不要额外运行 `tofu import`。

## Plan 和 Apply

```bash
tofu plan -out=plans/stop.tfplan
tofu show -no-color plans/stop.tfplan
```

当目标实例处于 `RUNNING` 时，必须确认 Plan 只包含指定实例：

```text
volcenginecc_ecs_instance.target  Import + Update

Plan: 1 to import, 0 to add, 1 to change, 0 to destroy.
```

详情中应显示 `status` 从 `RUNNING` 变为 `STOPPED`。如果显式指定了与当前值不同的
`stopped_mode`，该字段也会变更。目标已是 `STOPPED` 状态且没有其他差异时，Plan 只会
Import，随后会成为无变更状态。

确认后执行保存的计划：

```bash
tofu apply plans/stop.tfplan
tofu output
tofu plan
```

最后一次 Plan 应为 `No changes.`。

## 安全限制和后续操作

- 实例必须处于稳定的 `RUNNING` 或 `STOPPED` 状态；`STOPPING`、`STARTING`、异常等
  中间状态会在 Plan 阶段失败，避免与并发操作竞争。
- `prevent_destroy = true` 会拦截 `tofu destroy`，保护模板外创建的 ECS 实例。
- 本模板持续声明 `STOPPED`。如果不再需要由 OpenTofu 管理该状态，应先执行
  `tofu state rm volcenginecc_ecs_instance.target`，然后通过控制台、API 或专用启动模板
  恢复实例。不要把本模板中的状态临时改为 `RUNNING` 后又保留 State。
