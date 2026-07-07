@tool
extends EditorPlugin

## Asset Groups 插件入口:以主屏幕页签(与 2D/3D 同级)展示资源清单编辑器。
##
## 这是自研的**编辑器专用**工具,按 Godot 硬性要求必须落在 res://addons/ 下
## (EditorPlugin 只在此处被引擎识别),属于 directory.md「addons 只放第三方」规则的
## 唯一例外——它不参与运行时,不被 src/ 引用,不影响打包出的游戏。

const _DockScene := preload("dock/asset_group_dock.tscn")

var _dock: Control


func _enter_tree() -> void:
	_dock = _DockScene.instantiate()
	_dock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dock.size_flags_vertical = Control.SIZE_EXPAND_FILL
	get_editor_interface().get_editor_main_screen().add_child(_dock)
	_make_visible(false)


func _exit_tree() -> void:
	if _dock:
		get_editor_interface().get_editor_main_screen().remove_child(_dock)
		_dock.queue_free()
		_dock = null


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	if _dock:
		_dock.visible = visible


func _get_plugin_name() -> String:
	return "Asset Groups"


func _get_plugin_icon() -> Texture2D:
	return get_editor_interface().get_base_control().get_theme_icon("Folder", "EditorIcons")
