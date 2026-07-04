# 模块设计文档

每个 `framework/` 与 `platform/` 下的服务,**代码合并前必须有一篇模块文档**(用 [template.md](template.md))。`game/` 业务模块不强制,复杂系统(如战斗、任务)建议写。

模块文档回答的是"这个服务负责什么、边界在哪、怎么用、坏了会怎样",而不是逐行解释实现。

## 索引

| 模块 | 文档 | 状态 |
|---|---|---|
| SceneService | [scene-service.md](scene-service.md) | active(M1 已实现) |
| UIService | [ui-service.md](ui-service.md) | active(M1 已实现) |
| LogService | [log-service.md](log-service.md) | active(M0 已实现) |
| TimeService | — | 规划中 |
| ConfigService | — | 规划中 |
| SaveService | — | 规划中 |
| NetworkService | — | 规划中 |
| AssetService | — | 规划中 |
| AudioService | — | 规划中 |
| PlatformService(ads/android/ios) | — | 规划中 |
