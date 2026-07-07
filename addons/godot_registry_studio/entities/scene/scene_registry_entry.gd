class_name SceneRegistryEntry
extends Resource

## 场景注册表的一条登记:把 .tscn 拖进 [member scene] 即完成注册。
##
## 引用经 Godot UID 追踪——场景文件移动/改名不断链,也不需要改本表。
## id 默认取场景文件名(main_menu.tscn → &"main_menu"),需要时用
## [member id_override] 覆盖。登记后由面板生成 [Scenes] 常量类,业务代码经其引用。

#region Constants & Enums
const _EXPORT_SCENE := "PackedScene"
#endregion

#region Exports & State
## 直接拖 .tscn 进来。生成器只读它的路径/UID,运行时不加载本注册表,
## 场景仍由 SceneService 按需异步加载,不会因登记而提前进内存。
@export_custom(PROPERTY_HINT_RESOURCE_TYPE, _EXPORT_SCENE) var scene: PackedScene = null

## 场景 id,留空则取场景文件名。仅在同名冲突或想让 id 与文件名解耦时才填。
@export var id_override: StringName = &""

## 本场景关联的资产分组(可空)。SceneService 切入本场景前预载该组、离开后释放,
## 用于按场景控制内存峰值。留空表示本场景不走分组预载。
@export var asset_group: StringName = &""
#endregion
