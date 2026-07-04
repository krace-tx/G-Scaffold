# 启动管线设计

> status: active | 最后更新: 2026-07-04

## 为什么不用 Autoload 顺序初始化

Autoload 的 `_ready()` 是同步的,而移动端启动涉及大量**异步且会失败**的操作(SDK 初始化、远程配置拉取、登录)。失败处理在 Autoload 里无处安放。因此主场景固定为 `Boot.tscn`,由 Bootstrap 显式 `await` 各阶段。

## 启动阶段与失败策略

| # | 阶段 | 超时 | 失败策略 |
|---|---|---|---|
| 1 | Logger / 崩溃上报 | — | 不可失败(纯本地) |
| 2 | 本地配置 + 存档加载(含版本迁移) | — | **阻断**,弹重试对话框 |
| 3 | 平台 SDK 初始化(并行) | 5s | **降级**:替换为 Null 实现,游戏照常可玩 |
| 4 | 远程配置拉取 | 3s | **降级**:使用本地缓存/默认值 |
| 5 | 核心资产预热 | — | 阻断,重试 |
| 6 | 进入主菜单场景 | — | — |

核心原则:**广告/统计等第三方挂了,游戏必须照常能玩**。每个阶段"阻断还是降级"在 Bootstrap 中一目了然,不散落在各单例里。

## 伪代码骨架

```gdscript
# src/framework/core/bootstrap.gd
func run() -> void:
    App.log = LogService.new()
    await _phase(_load_local_config_and_save)      # 失败 → 阻断重试
    await _phase(_init_platform_sdks, 5.0)         # 失败 → Null 降级
    await _phase(_fetch_remote_config, 3.0)        # 失败 → 本地缓存
    await _phase(_preload_core_assets)
    App.scenes.replace(SceneIds.MAIN_MENU)
```

## 应用生命周期(切后台/返回键)

由 `App` 统一接管,转发为总线事件:

| 通知 | 处理 |
|---|---|
| `NOTIFICATION_APPLICATION_PAUSED` | `App.save.flush()`(iOS 唯一可靠保存点)+ `Bus.app_paused` |
| `NOTIFICATION_APPLICATION_RESUMED` | 重连、刷新远程配置、校时 + `Bus.app_resumed` |
| `NOTIFICATION_WM_GO_BACK_REQUEST` | `App.ui.handle_back()`:栈顶弹窗→关弹窗;无弹窗→场景返回;主菜单→退出确认 |

## 时间约束

所有每日重置、广告冷却、活动倒计时必须使用 `App.time.now()`(服务器时间 + 本地 tick 偏移),**禁止使用系统时钟**(玩家改时间是移动端第一大作弊手段)。
