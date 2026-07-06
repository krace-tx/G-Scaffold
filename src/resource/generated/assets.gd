class_name Assets
extends RefCounted

## 与 res://src/resource/data/asset_map.tres 保持同步。
## 增删条目时手改本文件(加载键用 uid://,源文件移动/改名后仍有效)。

const ICON: StringName = &"icon"
const LEVEL_ICON: StringName = &"level_icon"

## id → { uid(加载键), path(仅日志/可读性), group(资产分组) }。
const _TABLE: Dictionary = {
	ICON: { "uid": "uid://bc8ebymj1nbdj", "path": "res://icon.svg", "group": &"core" },
	LEVEL_ICON: { "uid": "uid://bc8ebymj1nbdj", "path": "res://icon.svg", "group": &"level" },
}

## 分组 → 组内 id 列表(生成期预计算,按组预载/释放遍历用)。
const _GROUPS: Dictionary = {
	&"core": [ICON],
	&"level": [LEVEL_ICON],
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


## 资产所属分组;未登记返回 &""。
static func group(id: StringName) -> StringName:
	var entry: Dictionary = _TABLE.get(id, {})
	return StringName(entry.get("group", &""))


## 某分组内的全部资产 id(生成期预计算);无此分组返回空数组。
static func ids_in_group(group_name: StringName) -> Array:
	var ids_list: Array = _GROUPS.get(group_name, [])
	return ids_list
