# ADR-0001: 类型化 App 聚合根,弃用字符串 ServiceLocator

> status: accepted | 日期: 2026-07-04

## 背景

框架有 10+ 个全局服务(UI、场景、音频、存档、网络…)。全部注册为 Autoload 会导致:初始化顺序靠加载顺序猜、异步初始化无处安放、测试时无法替换。经典替代是 ServiceLocator(`get_service("ui")`),但 GDScript 是动态语言,字符串 key 会失去类型检查、自动补全和"跳转到定义"——这恰恰是动态语言里最需要保住的东西。

## 决策

全项目只保留两个 Autoload:`App`(服务聚合根)和 `Bus`(信号总线)。`App` 持有所有服务的**类型化字段**(`var ui: UIService`),服务本身是普通 `class_name XxxService` 对象,由 Bootstrap 按序创建并注入。

## 考虑过的替代方案

- **每个服务一个 Autoload**:顺序不可控、无法 await 异步初始化、无法 mock,弃用。
- **字符串 key 的 ServiceLocator**:失去类型与补全,`get_service("uimanager")` 拼错要到运行时才炸,弃用。

## 后果

- 正面:`App.ui.open(...)` 全程有补全和类型检查;初始化顺序在 Bootstrap 里一目了然;测试直接 `App.platform = MockPlatform.new()`。
- 负面:新增服务要改两处(`app.gd` 字段 + Bootstrap 创建),接受此成本。
- 新约束:禁止再添加业务 Autoload;见 [guides/add-a-service.md](../../guides/add-a-service.md)。
