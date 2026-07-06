# SceneService 模块文档

> status: active | 最后更新: 2026-07-04 | 代码位置: `res://src/framework/managers/scene_service.gd`

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

场景 id → 路径的映射在统一清单 `resource/data/asset_manifest.tres` 的 `scenes` 数组里声明(经 Asset Groups 编辑器插件维护,见 [asset-groups.md](asset-groups.md)),代码里用 `SceneIds.XXX` 常量引用。

## 场景契约

所有顶层场景根节点继承 `BaseScene`:

```gdscript
func _on_enter(params: Dictionary) -> void   # 进场(实例化入树后、遮罩揭开前),可 await
func _on_exit() -> void                      # 真正销毁前调用,可 await(保存、断开监听)
```

切换流程:`旧场景._on_exit()` → 转场遮罩 → 异步加载新场景 → 实例化 → `新场景._on_enter()` → 揭开遮罩。

### 关于栈式切换(push/pop)的取舍

当前只支持 `replace`(整体替换、旧场景销毁),因此契约只有两个钩子,且 `_on_exit` 语义**严格限定为"销毁前"**,不是"离开前台"。这条语义边界是刻意画死的:

- 未定:项目是否会有"压入独立子场景(战斗/小游戏)、返回时把原场景**原样保活恢复**"的需求。这类需求才需要 push/pop,伴随 `_on_suspend` / `_on_resume(params)` 两个新钩子。
- 全屏菜单(暂停/设置/背包)**不构成**上栈理由——那是 UIService 分层弹窗的职责,不销毁底下场景。
- 现在**不预先实现** suspend/resume(YAGNI),但已在 `BaseScene` 里为这两个名字预留命名空间,并把 `_on_exit` 语义写死为"销毁前"——这样将来真上栈时,"保存进度"这类写在 `_on_exit` 里的逻辑不会因语义漂移而被临时挂起误触发。

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
- 单测:清单缺失 id、加载超时、连续快速调用 `replace`(应排队而非并发)
