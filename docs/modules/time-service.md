# TimeService 模块文档

> status: active | 最后更新: 2026-07-04 | 代码位置: `res://src/framework/core/time_service.gd`

## 职责与边界

**做什么**:提供权威时间源。所有每日重置、广告冷却、活动倒计时用 `now()`,基于服务器时间 + 本地单调 tick 推进,让玩家改设备时钟无法作弊。

**明确不做什么**:
- 不做时间格式化(`MM:SS` 之类)——那是 `TimeUtils`
- 不主动拉取服务器时间——由 NetworkService 登录握手拿到后调 `sync_from_server`(M4)
- 不做定时器/调度——用 Godot 原生 Timer / Tween

## 核心机制

校时那一刻记录两个锚点:服务器 unix 毫秒 `_sync_server_msec` 与本地 `Time.get_ticks_msec()`。之后 `now_msec()` = 服务器锚点 + (当前 tick − tick 锚点)。`Time.get_ticks_msec()` 是**单调递增**的开机计时,不受玩家改系统时钟影响。

**未校时降级**:还没 `sync_from_server` 时,`now()` 退化为系统时钟 `Time.get_unix_time_from_system()`,同时 `is_trusted()` 返回 false。业务对时间敏感的逻辑(领每日奖励、活动开关)应先查 `is_trusted()`,不可信时拒绝执行或延后到校时完成。

## 公开 API

```gdscript
func now() -> int                          # 当前 unix 秒
func now_msec() -> int                     # 当前 unix 毫秒
func sync_from_server(server_unix_msec: int) -> void   # M4 登录握手校准
func is_trusted() -> bool                  # 是否已校时(false=系统时钟,不可信)
```

## Bus 事件

无。

## 依赖

- 依赖:无(纯 `Time` 单例封装)
- 初始化时机:`LocalConfigStage` 创建;`NetworkStage` / 登录成功后(M4) `sync_from_server`;`app_resumed` 时应重新校时

## 持有的数据

- `_synced` / `_sync_server_msec` / `_sync_tick_msec`,进程生命周期存在,不持久化(每次启动重新校时)

## 失败策略

- 未校时:`now()` 仍返回值(系统时钟),但 `is_trusted()` 为 false,由调用方决定是否信任

## 测试要点

- 已无头验证(2026-07-04):未校时 `is_trusted` false 且 `now` 约等于系统时钟;`sync_from_server` 后 `is_trusted` true 且 `now` 基于服务器时间推进
- 后续单测(M6):校时后 tick 推进的精度、切后台恢复的重新校时
