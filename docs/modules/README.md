# 模块设计文档

每个 `framework/` 与 `platform/` 下的服务,**代码合并前必须有一篇模块文档**(用 [template.md](template.md))。`game/` 业务模块不强制,复杂系统(如战斗、任务)建议写。

模块文档回答的是"这个服务负责什么、边界在哪、怎么用、坏了会怎样",而不是逐行解释实现。

## 索引

| 模块 | 文档 | 状态 |
|---|---|---|
| SceneService | [scene-service.md](scene-service.md) | active(M1 已实现) |
| UIService | [ui-service.md](ui-service.md) | active(M1 已实现) |
| LogService | [log-service.md](log-service.md) | active(M0 已实现) |
| TimeService | [time-service.md](time-service.md) | active(M2 已实现) |
| ConfigService | [config-service.md](config-service.md) | active(M2 已实现) |
| SaveService | [save-service.md](save-service.md) | active(M2 已实现) |
| NetworkService | [network-service.md](network-service.md) | active(M4 已实现) |
| AssetService | [asset-service.md](asset-service.md) | active(M5 已实现) |
| AudioService | [audio-service.md](audio-service.md) | active(M5 已实现) |
| PlatformService(ads/analytics) | [platform-service.md](platform-service.md) | active(M3 已实现) |
| AssetManifest + Asset Groups 编辑器 | [asset-groups.md](asset-groups.md) | active(统一清单 + 可视化编辑器) |
