@tool
class_name GenerateFlags
extends RefCounted

## Generate 管线的分段开关:按 manifest 指纹只重写发生变化的注册表/查表类。

var scene_registry := true
var ui_registry := true
var asset_registry := true
var resource_registry := true
var scenes_accessor := true
var uis_accessor := true
var assets_accessor := true
var resources_accessor := true


func any_registry() -> bool:
	return scene_registry or ui_registry or asset_registry or resource_registry


func any_accessor() -> bool:
	return scenes_accessor or uis_accessor or assets_accessor or resources_accessor


func any_output() -> bool:
	return any_registry() or any_accessor()


func skipped_labels() -> PackedStringArray:
	var labels := PackedStringArray()
	if not scene_registry:
		labels.append("scene_registry.tres")
	if not ui_registry:
		labels.append("ui_registry.tres")
	if not asset_registry:
		labels.append("asset_map.tres")
	if not resource_registry:
		labels.append("resource_map.tres")
	if not scenes_accessor:
		labels.append("scenes.gd")
	if not uis_accessor:
		labels.append("uis.gd")
	if not assets_accessor:
		labels.append("assets.gd")
	if not resources_accessor:
		labels.append("resources.gd")
	return labels
