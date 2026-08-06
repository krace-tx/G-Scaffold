@tool
extends EditorPlugin

## Asset Groups 插件入口:以主屏幕页签(与 2D/3D 同级)展示资源清单编辑器。
##
## 这是自研的**编辑器专用**工具,按 Godot 硬性要求必须落在 res://addons/ 下
## (EditorPlugin 只在此处被引擎识别),属于 directory.md「addons 只放第三方」规则的
## 唯一例外——它不参与运行时,不被 src/ 引用,不影响打包出的游戏。

#region Constants & State
## 插件主界面的 UI 场景预制体。
const _DockScene := preload("editor/asset_group_dock.tscn")

## 实例化的主界面节点引用，用于控制显隐和生命周期清理。
var _dock: Control
#endregion

#region Plugin Lifecycle
## 插件激活或编辑器启动时调用。
## 职责：实例化 UI 面板，设置其布局属性，并注入到 Godot 编辑器的主屏幕区域。
func _enter_tree() -> void:
	_dock = _DockScene.instantiate()
	if _dock.has_method("setup_editor_interface"):
		_dock.setup_editor_interface(get_editor_interface())

	# 强行接管容器布局，确保面板撑满整个主屏幕工作区
	_dock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dock.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# 挂载到编辑器的 2D/3D/Script 所在的主工作区
	get_editor_interface().get_editor_main_screen().add_child(_dock)
	
	# 初始状态下必须隐藏，由 Godot 引擎通过 _make_visible 来控制显示时机
	_make_visible(false)

## 插件被禁用或编辑器关闭时调用。
## 职责：防泄漏护城河。必须严格解绑并清理动态生成的 _dock 节点，绝不能把垃圾留在编辑器的场景树中。
func _exit_tree() -> void:
	if _dock:
		get_editor_interface().get_editor_main_screen().remove_child(_dock)
		_dock.queue_free()
		_dock = null
#endregion

#region Main Screen Integration
## 声明该插件是一个“主屏幕工具”（与底部面板 Dock 不同）。
## 引擎收到 true 后，会在编辑器正中顶部生成一个专属的切换页签。
func _has_main_screen() -> bool:
	return true

## 引擎路由机制：当用户在顶部页签中切换（例如从 2D 切到本插件，或切走）时触发。
## [param visible]: 当前是否选中了本插件。
func _make_visible(visible: bool) -> void:
	if _dock:
		_dock.visible = visible

## 决定顶部页签上显示的文本名称。
func _get_plugin_name() -> String:
	return "Asset Groups"

## 决定顶部页签上显示的 Icon 图标。
## 复用引擎原生的 EditorIcons，让插件在视觉上与 Godot 融为一体，消灭廉价感。
func _get_plugin_icon() -> Texture2D:
	return get_editor_interface().get_base_control().get_theme_icon("Folder", "EditorIcons")
#endregion
