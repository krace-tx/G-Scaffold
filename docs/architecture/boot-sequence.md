# 启动管线设计

> status: active | 最后更新: 2026-07-06

## 为什么不用 Autoload 顺序初始化

Autoload 的 `_ready()` 是同步的,而移动端启动涉及大量**异步且会失败**的操作(SDK 初始化、远程配置拉取、登录)。失败处理在 Autoload 里无处安放。因此主场景固定为 `Boot.tscn`,由 `Bootstrap` 构造 `BootPipeline` 并 `await` 各 `BootStage`。

## 分层结构

```
Bootstrap (boot.tscn 根节点, core/bootstrap.gd)
    │
    ▼
BootPipeline (顺序调度、进度、跳过条件)
    │
    ├── StageRunner   计时、日志、失败策略执行
    ├── BootContext   宿主节点、progress_changed 信号
    └── BootStage[]   各阶段只关心:是否执行 / 执行逻辑 / 返回 Result / 声明失败策略
```

代码目录:

```
src/framework/core/
├── bootstrap.gd                 # 入口,仅构造 Pipeline 并 await run()
└── boot/
    ├── boot_pipeline.gd
    ├── boot_context.gd
    ├── boot_stage.gd            # @abstract 基类,LOG_TAG = "boot"
    ├── boot_failure_strategy.gd # FATAL / RETRY / DEGRADE / IGNORE
    ├── stage_runner.gd
    ├── stage_run_outcome.gd
    └── stages/
        ├── log_stage.gd
        ├── core_service_stage.gd
        ├── local_config_stage.gd
        ├── save_stage.gd
        ├── platform_stage.gd
        ├── network_stage.gd
        ├── asset_stage.gd
        └── enter_game_stage.gd
```

### 各组件职责

| 组件 | 职责 |
|---|---|
| `Bootstrap` | 挂在 `boot.tscn`,在 `_ready` 里启动管线 |
| `BootPipeline` | 顺序遍历 Stage 列表;`should_run` 为 false 则跳过;await 每步结果,失败时按策略终止或继续 |
| `BootContext` | 共享 `host`(Boot 节点)、当前序号、`progress_changed(index, total, stage_name)` |
| `StageRunner` | 单阶段计时;打 `[boot]` 日志;读取 `failure_strategy()` 决定终止或继续 |
| `BootStage` | 子类实现 `get_name()`、`run(ctx) -> Result`;可选覆盖 `should_run()`、`failure_strategy()` |

### 失败策略(`BootFailureStrategy.Kind`)

| 策略 | StageRunner 行为 |
|---|---|
| `FATAL` | 记 error,**终止**管线 |
| `RETRY` | 记 error,**终止**管线(由 UI 触发重新 `run()`,供存档 I/O 重试) |
| `DEGRADE` | 记 warn,**继续**后续阶段 |
| `IGNORE` | 记 info,**继续**后续阶段 |

核心原则:**广告/统计等第三方挂了,游戏必须照常能玩**。策略在各 Stage 的 `failure_strategy()` 中声明,**不在**各 Service 内部散落。

## 默认阶段列表

注册于 `BootPipeline.default_stages()`,顺序即执行顺序。

| Stage | 职责 | 注入 / 副作用 | 失败策略 | 备注 |
|---|---|---|---|---|
| `LogStage` | 创建 `App.log` | `LogService` | `FATAL` | 必须最先;纯本地,不可失败 |
| `CoreServiceStage` | 常驻场景树服务 | `SceneService` / `UIService` / `AssetService` / `AudioService` 挂到 `App` 下 | `FATAL` | 非 boot-sequence 旧表编号;切场景后仍需存活 |
| `LocalConfigStage` | 时间源 + 本地配置 | `App.time`、`App.config.load_local()` | `FATAL` | 对应旧「阶段 2」前半 |
| `SaveStage` | 存档加载与迁移 | `App.save.load_or_create()` | `RETRY` | 对应旧「阶段 2」后半;I/O 失败终止管线 |
| `PlatformStage` | 平台 SDK | `App.platform.setup()`(异步) | `DEGRADE` | 对应旧「阶段 3」;5s 超时与 Null 降级在 `PlatformService` 内 |
| `NetworkStage` | 登录 + 校时 + 远程配置 | `App.net` + Mock/`login_and_sync()` | `DEGRADE` | 对应旧「阶段 4」;Mock 表见 `network_stage.gd` |
| `AssetStage` | 核心资产预热 | `App.assets.preload_group(&"core")` | `FATAL` | 对应旧「阶段 5」 |
| `EnterGameStage` | 进入主菜单 | `App.scenes.replace(Scenes.MAIN_MENU)` | `FATAL` | 对应旧「阶段 6」;`replace` 内部 await 转场,避免 Boot 同帧切场景 |

## 入口伪代码

```gdscript
# src/framework/core/bootstrap.gd
func _run() -> void:
    await BootPipeline.new(self, BootPipeline.default_stages()).run()
```

单个 Stage 契约:

```gdscript
class_name ExampleStage
extends BootStage

func get_name() -> String:
    return "Example"

func failure_strategy() -> BootFailureStrategy.Kind:
    return BootFailureStrategy.Kind.DEGRADE

func run(_ctx: BootContext) -> Result:
    # 可 await;成功 return Result.ok(),失败 return Result.err("原因")
    return Result.ok()
```

## 新增启动阶段

1. 在 `core/boot/stages/` 新建 `XxxStage extends BootStage`。
2. 在 `BootPipeline.default_stages()` 按依赖顺序插入实例。
3. 在 `app.gd` 添加类型化字段(若尚未存在)。
4. 在对应模块文档的「初始化时机」写明 Stage 名与失败策略。

## 应用生命周期(切后台/返回键)

由 `App` 统一接管,转发为总线事件:

| 通知 | 处理 |
|---|---|
| `NOTIFICATION_APPLICATION_PAUSED` | `App.save.flush()`(iOS 唯一可靠保存点)+ `Bus.app_paused` |
| `NOTIFICATION_APPLICATION_RESUMED` | 重连、刷新远程配置、校时 + `Bus.app_resumed` |
| `NOTIFICATION_WM_GO_BACK_REQUEST` | `App.ui.handle_back()`:栈顶弹窗→关弹窗;无弹窗→场景返回;主菜单→退出确认 |

## 时间约束

所有每日重置、广告冷却、活动倒计时必须使用 `App.time.now()`(服务器时间 + 本地 tick 偏移),**禁止使用系统时钟**(玩家改时间是移动端第一大作弊手段)。
