class_name Uis
extends RefCounted

## -----------------------------------------------------------------------------
## AUTO-GENERATED FILE. DO NOT EDIT.
## Generator : Asset Groups
## Source    : res://src/resource/data/ui_registry.tres
##
## Edit the source manifest in Asset Groups and regenerate this file.
## Any manual changes will be overwritten.
## -----------------------------------------------------------------------------

## Static UI id registry. Use [Uis] constants instead of raw string ids.

#region Constants & State
const DEBUG_PANEL: StringName = &"debug_panel"
const SETTINGS_PANEL: StringName = &"settings_panel"

## Registered UIs: id -> { uid, path, layer, cache }.
const _TABLE: Dictionary = {
	DEBUG_PANEL: {
		"uid": "uid://d3b8g1v6k2mnp",
		"path": "res://src/game/ui/debug_panel.tscn",
		"layer": RuntimeUIEntry.Layer.WINDOW,
		"cache": RuntimeUIEntry.Cache.DESTROY,
	},
	SETTINGS_PANEL: {
		"uid": "uid://c8s2p1n5r3wqv",
		"path": "res://src/game/ui/settings_panel.tscn",
		"layer": RuntimeUIEntry.Layer.WINDOW,
		"cache": RuntimeUIEntry.Cache.DESTROY,
	},
}
#endregion

#region Public API
## Returns whether [param id] is registered.
static func has_id(id: StringName) -> bool:
	return _TABLE.has(id)

## Returns every registered UI id.
static func ids() -> Array:
	return _TABLE.keys()

## Returns the ResourceLoader key ([code]uid://[/code]) for [param id].
## Returns an empty string when [param id] is unknown.
static func load_path(id: StringName) -> String:
	var entry: Dictionary = _TABLE.get(id, {})
	return String(entry.get("uid", ""))

## Returns the source file path for [param id] (logging only).
## Returns an empty string when [param id] is unknown.
static func file_path(id: StringName) -> String:
	var entry: Dictionary = _TABLE.get(id, {})
	return String(entry.get("path", ""))

## Returns the render layer for [param id].
## Falls back to [code]RuntimeUIEntry.Layer.WINDOW[/code] when unknown.
static func layer(id: StringName) -> RuntimeUIEntry.Layer:
	var entry: Dictionary = _TABLE.get(id, {})
	var value: int = entry.get("layer", RuntimeUIEntry.Layer.WINDOW)
	return value as RuntimeUIEntry.Layer

## Returns the cache policy for [param id].
## Falls back to [code]RuntimeUIEntry.Cache.DESTROY[/code] when unknown.
static func cache(id: StringName) -> RuntimeUIEntry.Cache:
	var entry: Dictionary = _TABLE.get(id, {})
	var value: int = entry.get("cache", RuntimeUIEntry.Cache.DESTROY)
	return value as RuntimeUIEntry.Cache
#endregion
