class_name Scenes
extends RefCounted

## -----------------------------------------------------------------------------
## AUTO-GENERATED FILE. DO NOT EDIT.
## Generator : Asset Groups
## Source    : res://src/resource/data/scene_registry.tres
##
## Edit the source manifest in Asset Groups and regenerate this file.
## Any manual changes will be overwritten.
## -----------------------------------------------------------------------------

## Static scene id registry. Use [Scenes] constants instead of raw string ids.

#region Constants & State
const BOOT: StringName = &"boot"
const LEVEL: StringName = &"level"
const MAIN_MENU: StringName = &"main_menu"

## Registered scenes: id -> { uid, path }.
const _TABLE: Dictionary = {
	BOOT: {
		"uid": "uid://cwrbjroojaw05",
		"path": "res://src/game/scenes/boot.tscn",
	},
	LEVEL: {
		"uid": "uid://c5nd12asqpruc",
		"path": "res://src/game/scenes/level.tscn",
	},
	MAIN_MENU: {
		"uid": "uid://cqxmm0k4gj5vw",
		"path": "res://src/game/scenes/main_menu.tscn",
	},
}
#endregion

#region Public API
## Returns whether [param id] is registered.
static func has_id(id: StringName) -> bool:
	return _TABLE.has(id)

## Returns every registered scene id.
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
#endregion
