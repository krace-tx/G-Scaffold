class_name Scenes
extends RefCounted

## ⚠ 自动生成,请勿手改 —— 由「Registries」面板(addons/registry_manager)生成。
## 数据源:res://src/resource/data/scene_registry.tres,改动请在面板编辑后重新生成。

const MAIN_MENU: StringName = &"main_menu"
const LEVEL: StringName = &"level"

## id → { uid(加载键), path(仅日志/可读性), group(资产分组) }。
const _TABLE: Dictionary = {
	MAIN_MENU: { "uid": "uid://cqxmm0k4gj5vw", "path": "res://src/game/scenes/main_menu.tscn", "group": &"" },
	LEVEL: { "uid": "uid://c5nd12asqpruc", "path": "res://src/game/scenes/level.tscn", "group": &"level" },
}


static func has_id(id: StringName) -> bool:
	return _TABLE.has(id)


static func ids() -> Array:
	return _TABLE.keys()


## ResourceLoader 可用的加载键(uid://);未登记返回空字符串。
static func load_path(id: StringName) -> String:
	var entry: Dictionary = _TABLE.get(id, {})
	return String(entry.get("uid", ""))


## 人类可读的源文件路径(日志用);未登记返回空字符串。
static func file_path(id: StringName) -> String:
	var entry: Dictionary = _TABLE.get(id, {})
	return String(entry.get("path", ""))


## 本场景关联的资产分组;未登记或无分组返回 &""。
static func asset_group(id: StringName) -> StringName:
	var entry: Dictionary = _TABLE.get(id, {})
	return StringName(entry.get("group", &""))
