@tool
class_name EditUIEntry
extends Resource

## 编辑态 UI 条目：仅供 Dock UI 页读写。Generate 时转换为 [RuntimeUIEntry]。

## 界面所属的渲染层级。
enum Layer { HUD, WINDOW, POPUP, TOAST, LOADING, DEBUG }

## 界面关闭时的内存处理策略。
enum Cache { KEEP, DESTROY }

#region Exports & State
@export var id: StringName = &""
@export var scene_path: String = ""
@export var layer: Layer = Layer.WINDOW
@export var cache: Cache = Cache.DESTROY
#endregion
