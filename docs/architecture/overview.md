# 架构总览

> status: active | 最后更新: 2026-07-04

## 分层结构

```
┌─────────────────────────────────────────────┐
│  src/game/       业务层(允许与本游戏强耦合)  │
│    entities / scenes / ui / services(业务)   │
└──────────────┬──────────────────────────────┘
               │ 只能向下调用
┌──────────────▼──────────────────────────────┐
│  src/platform/   防腐层(隔离一切第三方 SDK)  │
│    ads / android / ios                       │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│  src/framework/  内核层(与"本游戏"无关)      │
│    autoloads / core / managers               │
└─────────────────────────────────────────────┘
   src/assets/ 与 src/resource/ 是纯数据:被所有层引用,不引用任何层
```

## 依赖铁律

1. **依赖只能单向向下**:`game → platform → framework`。`framework/` 中出现任何 `res://src/game/` 引用即违规。
2. **模块间横向通信走信号总线或由上层编排**,禁止互相 `get_node` / 持有引用。
3. **业务代码不直接触碰第三方 SDK**,一律经 `platform/` 门面。

## 全局入口

全项目只有两个 Autoload:

| Autoload | 职责 |
|---|---|
| `App` | 类型化服务聚合根。持有所有服务的类型化引用:`App.ui`、`App.scenes`、`App.save`… 由 Bootstrap 按序创建注入 |
| `Bus` | 全局信号总线。只承载"已发生的事实"(领域事件),见 [communication.md](communication.md) |

服务本身是普通对象(`class_name XxxService`),**不是 Autoload**。初始化顺序由 [启动管线](boot-sequence.md) 显式控制,不依赖 Autoload 加载顺序。

## 关键决策索引

| 决策 | ADR |
|---|---|
| 类型化 App 聚合根,弃用字符串 ServiceLocator | [ADR-0001](decisions/0001-typed-app-root.md) |
| Bus 只承载事实,命令走 API | [ADR-0002](decisions/0002-bus-facts-only.md) |
| 存档用版本化 JSON,禁止 Resource 进 user:// | [ADR-0003](decisions/0003-versioned-json-saves.md) |
| 平台能力经防腐层 + Null 实现 | [ADR-0004](decisions/0004-platform-null-providers.md) |
