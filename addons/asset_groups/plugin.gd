@tool
extends EditorPlugin

## Asset Groups 插件入口:把资源清单编辑器挂到编辑器底部面板。
##
## 这是自研的**编辑器专用**工具,按 Godot 硬性要求必须落在 res://addons/ 下
## (EditorPlugin 只在此处被引擎识别),属于 directory.md「addons 只放第三方」规则的
## 唯一例外——它不参与运行时,不被 src/ 引用,不影响打包出的游戏。

const _DockScene := preload("dock/asset_group_dock.tscn")

var _dock: Control


func _enter_tree() -> void:
	_dock = _DockScene.instantiate()
	add_control_to_bottom_panel(_dock, "Asset Groups")


func _exit_tree() -> void:
	if _dock:
		remove_control_from_bottom_panel(_dock)
		_dock.queue_free()
		_dock = null
