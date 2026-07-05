class_name Uis
extends RefCounted

## GENERATED — 本文件由 tools/registry_codegen.gd 生成,手改会在下次生成时丢失。
## 数据源:res://src/resource/data/ui_registry.tres(Inspector 里拖资源进条目即完成登记)。
## 重新生成:编辑器 File > Run 跑 res://tools/editor_regen_registries.gd,或命令行
## godot --headless --path . res://tools/generate_registries.tscn(加 `-- check` 只校验)。
##
## 加载键是 uid://:源文件移动/改名后本表依然有效(UID 稳定),只有增删条目、
## 改 id_override / 分组 / 层级等登记信息才需要重新生成。

const SETTINGS: StringName = &"settings"
const DEBUG: StringName = &"debug"

## id → { uid(加载键), path(仅日志/可读性), layer(渲染层), cache(缓存策略) }。
const _TABLE: Dictionary = {
	SETTINGS: { "uid": "uid://c8s2p1n5r3wqv", "path": "res://src/game/ui/settings_panel.tscn", "layer": UIRegistryEntry.Layer.POPUP, "cache": UIRegistryEntry.Cache.DESTROY },
	DEBUG: { "uid": "uid://d3b8g1v6k2mnp", "path": "res://src/game/ui/debug_panel.tscn", "layer": UIRegistryEntry.Layer.DEBUG, "cache": UIRegistryEntry.Cache.KEEP },
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


## 界面所属渲染层;未登记返回 WINDOW。
static func layer(id: StringName) -> UIRegistryEntry.Layer:
	var entry: Dictionary = _TABLE.get(id, {})
	var value: int = entry.get("layer", UIRegistryEntry.Layer.WINDOW)
	return value as UIRegistryEntry.Layer


## 界面关闭时的缓存策略;未登记返回 DESTROY。
static func cache(id: StringName) -> UIRegistryEntry.Cache:
	var entry: Dictionary = _TABLE.get(id, {})
	var value: int = entry.get("cache", UIRegistryEntry.Cache.DESTROY)
	return value as UIRegistryEntry.Cache
