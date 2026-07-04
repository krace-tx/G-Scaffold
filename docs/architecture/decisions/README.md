# 架构决策记录(ADR)

记录"为什么当初这么设计",防止半年后有人(包括自己)推翻正确决策或重蹈覆辙。

## 何时写 ADR

满足任意一条就写:

- 做了技术选型(用 A 不用 B)
- 定了一条全项目约束(如"禁止 Resource 进存档")
- 认真考虑过但**放弃**了某个方案(放弃的理由最有价值)

业务细节、实现技巧不用写 ADR,放模块文档里。

## 规则

- 文件名:`NNNN-短横线标题.md`,编号递增不复用
- 使用 [template.md](template.md)
- ADR **只增不改**:决策被推翻时,新写一篇 ADR,并把旧的标记为 `superseded by ADR-XXXX`
- 状态:`proposed`(讨论中)→ `accepted`(生效)→ `deprecated` / `superseded`

## 索引

| 编号 | 标题 | 状态 |
|---|---|---|
| [0001](0001-typed-app-root.md) | 类型化 App 聚合根,弃用字符串 ServiceLocator | accepted |
| [0002](0002-bus-facts-only.md) | 信号总线只承载事实,命令走 API | accepted |
| [0003](0003-versioned-json-saves.md) | 存档使用版本化 JSON,禁止 Resource 序列化到 user:// | accepted |
| [0004](0004-platform-null-providers.md) | 平台能力一律经防腐层访问,并提供 Null 实现 | accepted |
