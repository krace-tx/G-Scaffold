# 指南:新增一个框架服务

> status: active | 最后更新: 2026-07-04

适用:向 `framework/` 添加新的全局服务(XxxService)。**不要**为此新增 Autoload(见 [ADR-0001](../architecture/decisions/0001-typed-app-root.md))。

## 四步流程

### 1. 创建服务类

无场景树依赖 → `src/framework/core/`;需要挂树(定时器、CanvasLayer 等)→ `src/framework/managers/`。

```gdscript
# src/framework/core/foo_service.gd
class_name FooService
extends RefCounted   # 需要挂树则 extends Node

func setup() -> void:   # 异步初始化则 -> 带 await 的方法
    pass
```

### 2. 在 app.gd 添加类型化字段

```gdscript
# src/framework/autoloads/app.gd
var foo: FooService
```

### 3. 在 Bootstrap 对应阶段创建注入

根据依赖与失败策略选择阶段(见 [boot-sequence.md](../architecture/boot-sequence.md)):

```gdscript
App.foo = FooService.new()
await App.foo.setup()
```

想清楚:**初始化失败是阻断还是降级?** 写进模块文档。

### 4. 写模块文档

复制 [modules/template.md](../modules/template.md) 为 `modules/foo-service.md`,填完,并在 `modules/README.md` 索引表中登记。**没有模块文档的服务不予合并。**

## 自查清单

- [ ] 服务里没有 `res://src/game/` 引用(framework 不依赖 game)
- [ ] 需要广播的事件已在 Bus 中定义(过去式命名)
- [ ] 可失败操作返回 Result,不静默吞错
- [ ] 如果做了架构级取舍,补一篇 ADR
