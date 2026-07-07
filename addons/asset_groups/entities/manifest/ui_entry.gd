@tool
class_name UIEntry
extends Resource

## 编辑态 UI 条目:Dock UI 页直接读写,Generate 时写入 [UIRegistryEntry]。
##
## [member Layer] / [member Cache] 与 [UIRegistryEntry] 同名枚举按序对齐,
## 生成器经 int 转换,数值语义一致。

## 界面所属的渲染层。层级从低到高:HUD < Window < Popup < Toast < Loading < Debug。
enum Layer { HUD, WINDOW, POPUP, TOAST, LOADING, DEBUG }

## 关闭时的处理策略。KEEP:实例留在内存中复用;DESTROY:关闭即 queue_free。
enum Cache { KEEP, DESTROY }

#region Exports & State
@export var id: StringName = &""
@export var scene_path: String = ""
@export var layer: Layer = Layer.WINDOW
@export var cache: Cache = Cache.DESTROY
#endregion
