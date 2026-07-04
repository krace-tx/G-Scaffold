# SceneService 模块文档

> status: draft(代码未实现,本文兼作模块文档示例)| 最后更新: 2026-07-04 | 代码位置: `res://src/framework/managers/scene_service.gd`

## 职责与边界

**做什么**:管理顶层游戏场景的切换生命周期——异步加载(`ResourceLoader.load_threaded_*`)、转场动画、加载画面、以及场景的 `enter/exit` 异步钩子调度。全项目**唯一**允许调用 `change_scene` 系 API 的地方。

**明确不做什么**:
- 不维护场景栈(移动端 replace + 覆盖层足够,见下)——需要"返回上一场景"时由业务显式 `replace` 回去
- 不管理场景内的子场景/关卡分段加载——那是 `game/` 里关卡系统的职责
- 不管理 UI(弹窗、HUD)——那是 UIService 的职责

## 公开 API

```gdscript
func replace(scene_id: StringName, transition: StringName = &"fade") -> void  # 切换主场景,自动走加载画面
func reload_current() -> void                                                 # 重载当前场景(如"重开本关")
func get_current_id() -> StringName                                           # 当前场景 id
```

场景 id → 路径的映射在 `resource/data/scene_registry.tres` 中声明,代码里用 `SceneIds.XXX` 常量引用。

## 场景契约

所有顶层场景根节点继承 `BaseScene`:

```gdscript
func _on_enter(params: Dictionary) -> void   # 进场,可 await(如播放入场演出)
func _on_exit() -> void                      # 退场,可 await(如保存、断开监听)
```

切换流程:`旧场景._on_exit()` → 转场遮罩 → 异步加载新场景 → 实例化 → `新场景._on_enter()` → 揭开遮罩。

## Bus 事件

| 方向 | 信号 | 触发时机 |
|---|---|---|
| 发出 | `Bus.scene_changed(scene_id)` | 新场景 `_on_enter` 完成后 |
| 监听 | 无 | 命令一律经 API 进入,不监听总线 |

## 依赖

- 依赖:`App.log`、`App.assets`(预载场景资源组)
- 初始化时机:Bootstrap 第 1 阶段之后即可用(切场景在第 6 阶段才首次发生)

## 失败策略

- 场景加载失败(资源缺失):记录 error 日志,停留在当前场景,发出 `Bus.scene_change_failed(scene_id)`;**禁止**留下黑屏
- `_on_enter` 中的异常由场景自身兜底,SceneService 设置超时保护(10s)强制揭开遮罩

## 测试要点

- 编辑器:调试面板提供任意场景跳转按钮
- 单测:注册表缺失 id、加载超时、连续快速调用 `replace`(应排队而非并发)
