class_name Assets
extends RefCounted

## GENERATED — 本文件由 tools/registry_codegen.gd 生成,手改会在下次生成时丢失。
## 数据源:res://src/resource/data/asset_map.tres(Inspector 里拖资源进条目即完成登记)。
## 重新生成:编辑器 File > Run 跑 res://tools/editor_regen_registries.gd,或命令行
## godot --headless --path . res://tools/generate_registries.tscn(加 `-- check` 只校验)。
##
## 加载键是 uid://:源文件移动/改名后本表依然有效(UID 稳定),只有增删条目、
## 改 id_override / 分组 / 层级等登记信息才需要重新生成。

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
