@tool
class_name PluginConfig
extends RefCounted

## 插件级配置:路径与展示信息来自 ProjectSettings,不硬编码宿主工程结构。

#region Constants & Enums
const SETTING_PREFIX := "registry_studio/"

const SETTING_SCENE_REGISTRY := SETTING_PREFIX + "scene_registry"
const SETTING_UI_REGISTRY := SETTING_PREFIX + "ui_registry"
const SETTING_ASSET_REGISTRY := SETTING_PREFIX + "asset_registry"
const SETTING_SCENE_OUTPUT := SETTING_PREFIX + "scene_output"
const SETTING_UI_OUTPUT := SETTING_PREFIX + "ui_output"
const SETTING_ASSET_OUTPUT := SETTING_PREFIX + "asset_output"
const SETTING_PLUGIN_PATH := SETTING_PREFIX + "plugin_path"
#endregion

#region Public API
## 向 ProjectSettings 注册默认值(幂等,重复调用安全)。
static func register_project_settings() -> void:
	_add_default(SETTING_SCENE_REGISTRY, "res://src/resource/data/scene_registry.tres")
	_add_default(SETTING_UI_REGISTRY, "res://src/resource/data/ui_registry.tres")
	_add_default(SETTING_ASSET_REGISTRY, "res://src/resource/data/asset_map.tres")
	_add_default(SETTING_SCENE_OUTPUT, "res://src/resource/generated/scenes.gd")
	_add_default(SETTING_UI_OUTPUT, "res://src/resource/generated/uis.gd")
	_add_default(SETTING_ASSET_OUTPUT, "res://src/resource/generated/assets.gd")
	_add_default(SETTING_PLUGIN_PATH, "res://addons/godot_registry_studio")


static func scene_registry_path() -> String:
	return _get_path(SETTING_SCENE_REGISTRY)


static func ui_registry_path() -> String:
	return _get_path(SETTING_UI_REGISTRY)


static func asset_registry_path() -> String:
	return _get_path(SETTING_ASSET_REGISTRY)


static func scene_output_path() -> String:
	return _get_path(SETTING_SCENE_OUTPUT)


static func ui_output_path() -> String:
	return _get_path(SETTING_UI_OUTPUT)


static func asset_output_path() -> String:
	return _get_path(SETTING_ASSET_OUTPUT)


static func plugin_path() -> String:
	return _get_path(SETTING_PLUGIN_PATH)


static func entity_path(p_relative: String) -> String:
	return plugin_path().path_join(p_relative)
#endregion

#region Internal
static func _add_default(p_key: String, p_value: String) -> void:
	if not ProjectSettings.has_setting(p_key):
		ProjectSettings.set_setting(p_key, p_value)


static func _get_path(p_key: String) -> String:
	return String(ProjectSettings.get_setting(p_key, ""))
#endregion
