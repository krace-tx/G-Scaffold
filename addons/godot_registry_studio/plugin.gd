@tool
extends EditorPlugin

## Godot Registry Studio: 管理 Scene / UI / Asset 注册表(.tres)并生成运行时查 path 的常量类。

#region Constants & Enums
const MENU_GENERATE := "Registry Studio/Generate All"
const _PANEL_SCENE: PackedScene = preload("res://addons/godot_registry_studio/ui/studio_panel.tscn")
#endregion

#region Exports & State
var _registry_service: RegistryService
var _studio_panel: StudioPanel
#endregion

#region Lifecycle
func _enter_tree() -> void:
	PluginConfig.register_project_settings()
	_registry_service = RegistryService.new()
	_studio_panel = _PANEL_SCENE.instantiate() as StudioPanel
	add_control_to_bottom_panel(_studio_panel, "Registry Studio")
	_studio_panel.setup(_registry_service)
	add_tool_menu_item(MENU_GENERATE, _on_generate_all)
	make_bottom_panel_item_visible(_studio_panel)


func _exit_tree() -> void:
	remove_tool_menu_item(MENU_GENERATE)
	if _studio_panel != null:
		remove_control_from_bottom_panel(_studio_panel)
		_studio_panel.queue_free()
		_studio_panel = null
	_registry_service = null
#endregion

#region Internal
func _on_generate_all() -> void:
	var res := _registry_service.generate_all()
	if res.is_err():
		RegistryLogger.error(str(res.error))
		return
	RegistryLogger.info("Generation complete.")
	if _studio_panel != null:
		_studio_panel.set_status("Ready")
#endregion
