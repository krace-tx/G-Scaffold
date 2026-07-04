# XxxService 模块文档

> status: draft | 最后更新: YYYY-MM-DD | 代码位置: `res://src/framework/...`

## 职责与边界

**做什么**(一段话,说不清楚说明模块切分有问题):

**明确不做什么**(防止未来功能往这里堆):
- ……(例:AudioService 不管理"哪个场景放什么 BGM"——那是业务决策,放 game/)

## 公开 API

只列稳定对外的方法签名与一句话说明,内部方法不写。

```gdscript
func xxx(param: Type) -> ReturnType  # 说明
```

## Bus 事件

| 方向 | 信号 | 触发时机 |
|---|---|---|
| 发出 | `Bus.xxx_completed(...)` | …… |
| 监听 | `Bus.app_paused` | …… |

## 依赖

- 依赖的其他服务:(例:依赖 `App.log`、`App.assets`)
- 初始化时机:Bootstrap 第 N 阶段

## 持有的数据

- 内存中维护什么状态、生命周期多长
- 关联的配置文件(如 `resource/data/xxx.tres`)

## 失败策略

- 哪些操作会失败、失败时返回什么(Result / 空值 / 降级行为)
- 是否影响启动(阻断 / 降级,见 [boot-sequence.md](../architecture/boot-sequence.md))

## 测试要点

- 编辑器内如何验证(Null 实现 / 调试面板)
- 单测覆盖哪些关键路径
