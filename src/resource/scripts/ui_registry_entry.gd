class_name UIRegistryEntry
extends Resource

## UI 注册表的一条登记:把界面 .tscn 拖进 [member scene] + 声明层级与缓存策略。
##
## 引用经 Godot UID 追踪,移动/改名不断链。id 默认取场景文件名,用
## [member id_override] 覆盖(如 settings_panel.tscn 想叫 &"settings")。
## 登记后跑一次生成器,业务代码经生成的 [Uis] 常量类引用。

## 界面所属的渲染层。层级从低到高:HUD < Window < Popup < Toast < Loading < Debug。
## 实际 CanvasLayer.layer 数值由 UIService 统一分配(见 ui_service.gd),此处只是逻辑分类。
enum Layer { HUD, WINDOW, POPUP, TOAST, LOADING, DEBUG }

## 关闭时的处理策略。KEEP:实例留在内存中复用(高频界面,省实例化开销);
## DESTROY:关闭即 queue_free(低频 / 大界面,省内存)。
enum Cache { KEEP, DESTROY }

#region Exports & State
## 直接拖界面 .tscn 进来。生成器只读它的路径/UID,运行时按需加载。
@export var scene: PackedScene

## 界面 id,留空则取场景文件名。
@export var id_override: StringName = &""

@export var layer: Layer = Layer.WINDOW
@export var cache: Cache = Cache.DESTROY
#endregion
