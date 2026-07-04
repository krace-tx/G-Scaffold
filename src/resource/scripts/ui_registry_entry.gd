class_name UIRegistryEntry
extends Resource

## UI 注册表的一条记录:id → 场景路径 + 所在层级 + 缓存策略。
## 由 [UIRegistry] 持有一组,数据在 res://src/resource/data/ui_registry.tres。

## 界面所属的渲染层。层级从低到高:HUD < Window < Popup < Toast < Loading < Debug。
## 实际 CanvasLayer.layer 数值由 UIService 统一分配(见 ui_service.gd),此处只是逻辑分类。
enum Layer { HUD, WINDOW, POPUP, TOAST, LOADING, DEBUG }

## 关闭时的处理策略。KEEP:实例留在内存中复用(高频界面,省实例化开销);
## DESTROY:关闭即 queue_free(低频 / 大界面,省内存)。
enum Cache { KEEP, DESTROY }

#region Exports & State
@export var id: StringName = &""
@export var scene_path: String = ""
@export var layer: Layer = Layer.WINDOW
@export var cache: Cache = Cache.DESTROY
#endregion
