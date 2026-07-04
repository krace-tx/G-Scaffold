# 项目文档中心

> 本目录被 `.gdignore` 排除,Godot 编辑器不会扫描,不会出现在 FileSystem 面板中。

## 文档地图

| 目录 | 内容 | 什么时候读 |
|---|---|---|
| [doc-graph.md](doc-graph.md) | 文档网络图谱:引用关系、枢纽与孤岛 | 想快速鸟瞰整个文档体系时 |
| [plan/](plan/development-plan.md) | 开发计划、迭代计划与排期文档 | 开工前;每完成一项回来勾选 |
| [architecture/](architecture/overview.md) | 架构总览、启动管线、通信规范 | 入职第一天;做任何跨模块改动前 |
| [architecture/decisions/](architecture/decisions/README.md) | ADR 架构决策记录 | 想知道"为什么当初这么设计"时 |
| [modules/](modules/README.md) | 各服务/模块的设计文档 | 使用或修改某个服务前 |
| [conventions/](conventions/directory.md) | 目录、命名、编码、Git 规范 | 写第一行代码前;Code Review 时 |
| [guides/](guides/add-a-service.md) | 常见开发任务的操作指南 | 加 UI、加服务、接 SDK 时照着做 |

## 文档写作规则

文档不是负担,是架构的一部分。规则只有四条:

1. **代码与文档同 PR**:新增框架服务必须附带 `modules/` 文档;修改服务行为必须同步更新其文档。文档没更新的 PR 不予合并。
2. **架构级决策必须留 ADR**:凡是"以后有人会问为什么"的决策(选型、约束、放弃的方案),写一篇 ADR。业务细节不用。
3. **过期文档比没有文档更糟**:发现文档与代码不符,要么当场改,要么在文档头部标记 `status: outdated` 并建任务。
4. **每篇文档头部标注状态**:`draft`(讨论中)/ `active`(生效)/ `deprecated`(已废弃,保留供考古)。

## 新人阅读顺序

1. `architecture/overview.md` — 分层与依赖规则(10 分钟)
2. `architecture/communication.md` — Bus 与 API 的使用铁律(5 分钟)
3. `conventions/directory.md` — 新文件该放哪(5 分钟)
4. 动手前再按需查 `guides/`
