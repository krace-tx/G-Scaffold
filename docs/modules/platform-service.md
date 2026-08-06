# PlatformService 模块文档

> status: active | 代码位置: `res://src/platform/platform_service.gd`

## 职责与边界

**做什么**:平台能力(统计、账号登录……)的聚合门面与防腐层。业务通过 `App.platform.firebase_analytics` / `App.platform.auth` 使用能力，永远不直接触碰 SDK。按 OS/编辑器选择实现，初始化失败/超时自动降级为 Null。

**明确不做什么**:
- 不在门面外暴露任何 SDK 类型 / `OS.get_name()` 分支——平台判断只在具体 Provider/工厂里
- 不做具体 SDK 封装——那在各 `*Provider` 实现里

## 结构

```
platform_provider.gd               @abstract 共同基类: initialize() -> bool
platform_service.gd                门面(Node): App.platform, 并行初始化 + 超时降级
analytics/
  firebase_analytics_provider.gd   Firebase 统计能力服务
auth/
  auth_provider.gd                 账号与登录能力服务 (Google / Apple Sign-In)
```

## 公开 API

```gdscript
# 门面属性
App.platform.firebase_analytics: FirebaseAnalyticsProvider
App.platform.auth: AuthProvider
```

## 初始化与降级

`PlatformStage` 调 `PlatformService.setup()`: 各 provider **并行** `initialize()`, 带有超时判定（15.0 秒）。
- 成功 → 用真实现
- `initialize()` 返回 false(失败)或超时 → **自动降级**，日志 warn

## 依赖

- 依赖: `App.log`; PlatformService 是 Node(需 `get_tree()` 做超时轮询), 挂在 App 下
- 初始化时机: `PlatformStage`

## 失败策略

- 单个 provider 失败/超时: 降级 Null/Fallback, 不阻断启动

