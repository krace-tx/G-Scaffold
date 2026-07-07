class_name Uis
extends RefCounted

## ⚠ 自动生成,请勿手改 —— 由 Asset Groups 面板(addons/asset_groups) Generate 生成。
## 数据源:res://src/resource/data/ui_registry.tres

const DEBUG_PANEL: StringName = &"debug_panel"
const SETTINGS_PANEL: StringName = &"settings_panel"

## id → { uid(加载键), path(仅日志/可读性), layer(渲染层), cache(缓存策略) }。
const _TABLE: Dictionary = {
	DEBUG_PANEL: { "uid": "uid://d3b8g1v6k2mnp", "path": "res://src/game/ui/debug_panel.tscn", "layer": UIRegistryEntry.Layer.WINDOW, "cache": UIRegistryEntry.Cache.DESTROY },
	SETTINGS_PANEL: { "uid": "uid://c8s2p1n5r3wqv", "path": "res://src/game/ui/settings_panel.tscn", "layer": UIRegistryEntry.Layer.WINDOW, "cache": UIRegistryEntry.Cache.DESTROY },
}

static func has_id(id: StringName) -> bool:
	return _TABLE.has(id)

static func ids() -> Array:
	return _TABLE.keys()

static func load_path(id: StringName) -> String:
	var entry: Dictionary = _TABLE.get(id, {})
	return String(entry.get("uid", ""))

static func file_path(id: StringName) -> String:
	var entry: Dictionary = _TABLE.get(id, {})
	return String(entry.get("path", ""))

static func layer(id: StringName) -> UIRegistryEntry.Layer:
	var entry: Dictionary = _TABLE.get(id, {})
	var value: int = entry.get("layer", UIRegistryEntry.Layer.WINDOW)
	return value as UIRegistryEntry.Layer

static func cache(id: StringName) -> UIRegistryEntry.Cache:
	var entry: Dictionary = _TABLE.get(id, {})
	var value: int = entry.get("cache", UIRegistryEntry.Cache.DESTROY)
	return value as UIRegistryEntry.Cache
