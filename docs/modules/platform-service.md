# PlatformService 模块文档

> status: active | 最后更新: 2026-07-04 | 代码位置: `res://src/platform/platform_service.gd`

## 职责与边界

**做什么**:平台能力(广告、统计……)的聚合门面与防腐层。业务通过 `App.platform.ads` / `App.platform.analytics` 使用能力,永远不接触具体 SDK。按 OS/编辑器选择实现,初始化失败/超时自动降级为 Null。见 [ADR-0004](../architecture/decisions/0004-platform-null-providers.md)。

**明确不做什么**:
- 不替业务决定"发不发奖"——`show_rewarded` 只返回 [AdResult],发奖(emit `Bus.ad_reward_granted`)是业务的事
- 不在门面外暴露任何 SDK 类型 / `OS.get_name()` 分支——平台判断只在工厂里
- 不做具体 SDK 封装——那在各 `*Provider` 实现里

## 结构

```
platform_provider.gd        @abstract 共同基类:initialize() -> bool
platform_service.gd         门面(Node):App.platform,并行初始化 + 超时降级
ads/
  ad_provider.gd            @abstract:show_rewarded / is_ready
  ad_result.gd              值对象:REWARDED/DISMISSED/FAILED/NOT_READY
  null_ad_provider.gd       Null 实现:模拟观看 1s 后发奖
  admob_android_provider.gd 真实现骨架(TODO,SDK 接入填充)
  admob_ios_provider.gd     真实现骨架
  ad_provider_factory.gd    按 OS/编辑器选实现
analytics/
  analytics_provider.gd     @abstract:track
  null_analytics_provider.gd Null 实现:打点落日志
  analytics_provider_factory.gd
```

## 公开 API

```gdscript
# 门面
App.platform.ads: AdProvider
App.platform.analytics: AnalyticsProvider

# AdProvider
func show_rewarded(placement: StringName) -> AdResult   # 异步
func is_ready(placement: StringName) -> bool

# AnalyticsProvider
func track(event: StringName, params: Dictionary) -> void
```

典型发奖流程(业务侧):
```gdscript
var res := await App.platform.ads.show_rewarded(&"double_coins")
if res.is_rewarded():
    Bus.ad_reward_granted.emit(&"double_coins")
```

## 初始化与降级

Bootstrap 阶段 3 调 `setup()`:各 provider **并行** `initialize()`,每个 5s 超时。
- 成功 → 用真实现
- `initialize()` 返回 false(失败)或超时 → **降级为对应 Null 实现**,日志 warn

编辑器/不支持的平台由工厂直接给 Null。因此 F5 与 CI 无头都能跑通完整"请求→观看→发奖"流程,不依赖真机;广告 SDK 挂了游戏照常能玩。

## Bus 事件

| 方向 | 信号 | 说明 |
|---|---|---|
| 相关 | `Bus.ad_reward_granted(placement)` | 由**业务**在 `is_rewarded()` 为真时发,不是 PlatformService |

## 依赖

- 依赖:`App.log`;PlatformService 是 Node(需 `get_tree()` 做超时轮询),挂在 App 下
- 初始化时机:Bootstrap 阶段 3

## 失败策略

- 单个 provider 失败/超时:降级 Null,不阻断启动
- `show_rewarded` 失败:返回 `AdResult.failed(msg)`,业务据 `is_rewarded()` 决定不发奖

## 测试要点

- 已无头验证(2026-07-04,11 项):编辑器下为 Null 实现、`show_rewarded` → `is_rewarded` → `Bus.ad_reward_granted`、`AdResult` 语义、**强制 `initialize` 返回 false → 降级 Null 且仍可发奖**、`analytics.track` 不崩
- 真机 SDK 联调:填充 `admob_*_provider.gd` 后单独排期(每 SDK 2~4 天,见 plan)
