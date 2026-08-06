@tool
class_name RuntimeUIEntry
extends Resource

## 运行时 UI 注册表的一条登记,由 [RegistryGenerator] 从 [EditUIEntry] 生成。
##
## 存路径字符串而非 PackedScene 引用,避免 load 本表时把所有界面同步拉进内存。

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
