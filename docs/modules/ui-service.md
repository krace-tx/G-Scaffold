# UIService 模块文档

> status: active | 最后更新: 2026-07-04 | 代码位置: `res://src/framework/managers/ui_service.gd`

## 职责与边界

**做什么**:按层级管理界面(HUD/弹窗/菜单等)的打开、关闭、返回键路由与缓存复用。全项目打开界面唯一入口是 [method open],统一管理层级 z 序、每层的界面栈、Android 返回键、KEEP/DESTROY 缓存。

**明确不做什么**:
- 不管理顶层场景切换——那是 SceneService。界面常驻在 App 下的 CanvasLayer,跨场景不销毁
- 不管理界面内部业务逻辑(按钮点了干嘛)——那是各界面脚本自己的事
- 不决定"哪个场景显示哪些 HUD"——那是业务/场景代码调用 `open` 的决策

## 分层设计

六个逻辑层,对应 CanvasLayer.layer 数值,**刻意与 SceneService 转场遮罩的 `layer=100` 错开**:

| 逻辑层 | layer 值 | 用途 | 转场遮罩下 |
|---|---|---|---|
| HUD | 10 | 游戏内常驻血条/按钮 | 被盖住 |
| Window | 20 | 全屏菜单(设置/背包) | 被盖住 |
| Popup | 30 | 对话框/确认框 | 被盖住 |
| Toast | 40 | 瞬时提示 | 被盖住 |
| Loading | 50 | 加载画面 | 被盖住 |
| Debug | 110 | 调试面板 | **仍可见**(转场时也能调试) |

## 公开 API

```gdscript
func open(ui_id: StringName, params: Dictionary = {}) -> BaseUI   # 打开(已开则返回现有实例)
func close(ui_id: StringName) -> void                             # 关闭(按缓存策略留存或销毁)
func handle_back() -> bool                                        # 返回键路由;true=被界面消费
func is_open(ui_id: StringName) -> bool                           # 是否打开中
```

界面 id → 场景路径/层级/缓存策略的映射在统一清单 `resource/data/asset_manifest.tres` 的 `uis` 数组里(经 Asset Groups 编辑器插件维护,见 [asset-groups.md](asset-groups.md)),代码里用 `UIIds.XXX` 常量引用,清单路径经 `ResPaths.MANIFEST`。

## 界面契约

界面预制体根节点继承 `BaseUI`(extends Control):

```gdscript
func _on_open(params: Dictionary) -> void   # 入树后调用
func _on_close() -> void                     # 移除前调用,必须断开对外信号连接
func _on_back() -> bool                      # 返回键;true=自行消费,false=让 UIService 默认关闭
```

## 缓存策略

- `KEEP`:关闭时脱离层树暂存于内存,下次 `open` 直接复用(高频界面,省实例化开销)。**复用时不会重跑 `_ready`**,状态残留需界面自己在 `_on_open`/`_on_close` 里清。
- `DESTROY`:关闭即 `queue_free`(低频/大界面,省内存)。

## Bus 事件

| 方向 | 信号 | 触发时机 |
|---|---|---|
| 发出 | `Bus.ui_opened(ui_id)` | 实例入树、`_on_open` 已调用后 |
| 发出 | `Bus.ui_closed(ui_id)` | `_on_close` 已调用、已移出层后 |
| 监听 | 无 | 命令经 API,不监听总线 |

## 依赖

- 依赖:`App.log`、`Bus`;返回键由 `App._notification` 的 `NOTIFICATION_WM_GO_BACK_REQUEST` 转发进 `handle_back()`
- 初始化时机:Bootstrap 内核接线阶段(与 SceneService 一同),挂在 App 下

## 失败策略

- 未知 ui_id / 加载失败:记录 error 日志,`open` 返回 null,不崩溃
- `close` 未打开的 id:静默返回

## 测试要点

- 已无头验证(2026-07-04):`open` 返回实例、`is_open` 开关、`close` 后状态、返回键关栈顶弹窗并返回 true、空栈时 `handle_back` 返回 false,`ui_opened`/`ui_closed` 事件按序发出
- 后续单测(M6):KEEP 复用不重建实例、DESTROY 确实释放、多层栈的返回键优先级(Popup 先于 Window)
