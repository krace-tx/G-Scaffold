@tool
class_name StudioPanel
extends Control

## Registry Studio 可视化编辑器:管理 Scene / UI / Asset 三张 .tres 注册表,
## 一键生成供 Framework 运行时查 path 的常量类。

const _TREE_META_INDEX := &"entry_index"

#region Exports & State
var _service: RegistryService
var _descriptors: Array[RegistryDescriptor] = []
var _registries: Dictionary = {}
var _active_index: int = 0

@onready var _tab_bar: TabBar = $Root/Header/TabBar
@onready var _generate_button: Button = $Root/Header/GenerateButton
@onready var _status_label: Label = $Root/Header/StatusLabel
@onready var _add_button: Button = $Root/Toolbar/AddButton
@onready var _remove_button: Button = $Root/Toolbar/RemoveButton
@onready var _open_tres_button: Button = $Root/Toolbar/OpenTresButton
@onready var _entry_tree: Tree = $Root/EntryTree
@onready var _footer_label: Label = $Root/Footer
#endregion

#region Lifecycle
func _ready() -> void:
	_wire_signals()
	if _service != null:
		_bootstrap()
#endregion

#region Public API
## 注入 [RegistryService] 并加载全部 .tres。
func setup(p_service: RegistryService) -> void:
	_service = p_service
	if is_node_ready():
		_bootstrap()
#endregion

#region Internal
func _wire_signals() -> void:
	_tab_bar.tab_changed.connect(_on_tab_changed)
	_generate_button.pressed.connect(_on_generate_pressed)
	_add_button.pressed.connect(_on_add_pressed)
	_remove_button.pressed.connect(_on_remove_pressed)
	_open_tres_button.pressed.connect(_on_open_tres_pressed)
	_entry_tree.item_selected.connect(func() -> void: _remove_button.disabled = false)
	_entry_tree.nothing_selected.connect(func() -> void: _remove_button.disabled = true)


func _bootstrap() -> void:
	_descriptors = DescriptorFactory.all()
	_tab_bar.clear_tabs()
	_registries.clear()
	for descriptor in _descriptors:
		_tab_bar.add_tab(String(descriptor.display_name))
		var load_res := _service.load_registry(descriptor)
		if load_res.is_err():
			_registries[descriptor.id] = null
			RegistryLogger.error("%s: %s" % [descriptor.display_name, load_res.error])
			continue
		_registries[descriptor.id] = load_res.value
	_active_index = 0
	_reload_tree()
	_update_footer()


func _active_descriptor() -> RegistryDescriptor:
	if _active_index < 0 or _active_index >= _descriptors.size():
		return null
	return _descriptors[_active_index]


func _active_registry() -> Resource:
	var descriptor := _active_descriptor()
	if descriptor == null:
		return null
	return _registries.get(descriptor.id)


func _on_tab_changed(p_tab: int) -> void:
	_active_index = p_tab
	_reload_tree()
	_update_footer()


func _configure_tree_columns(p_descriptor: RegistryDescriptor) -> void:
	_entry_tree.columns = 2 + p_descriptor.columns.size()
	_entry_tree.set_column_title(0, "ID")
	_entry_tree.set_column_title(1, "Resource")
	for index in p_descriptor.columns.size():
		_entry_tree.set_column_title(index + 2, p_descriptor.columns[index].key)


func _reload_tree() -> void:
	_entry_tree.clear()
	var descriptor := _active_descriptor()
	var registry := _active_registry()
	if descriptor == null:
		return
	_configure_tree_columns(descriptor)
	if registry == null:
		return
	var entries: Array = _service.get_entries(registry)
	for index in entries.size():
		var entry: Resource = entries[index]
		var item := _entry_tree.create_item()
		item.set_metadata(0, { _TREE_META_INDEX: index })
		item.set_text(0, _display_id(descriptor, entry))
		item.set_text(1, _display_resource(descriptor, entry))
		for col_index in descriptor.columns.size():
			var column: RegistryColumn = descriptor.columns[col_index]
			item.set_text(col_index + 2, String(entry.get(column.prop)))


func _display_id(p_descriptor: RegistryDescriptor, p_entry: Resource) -> String:
	var override: StringName = p_entry.get(&"id_override")
	if not String(override).is_empty():
		return String(override)
	var resource: Resource = p_entry.get(p_descriptor.resource_field)
	if resource != null and not resource.resource_path.is_empty():
		return resource.resource_path.get_file().get_basename()
	return "(pending)"


func _display_resource(p_descriptor: RegistryDescriptor, p_entry: Resource) -> String:
	var resource: Resource = p_entry.get(p_descriptor.resource_field)
	if resource == null or resource.resource_path.is_empty():
		return "(none)"
	return resource.resource_path


func _update_footer() -> void:
	var descriptor := _active_descriptor()
	if descriptor == null:
		_footer_label.text = ""
		return
	_footer_label.text = (
		"数据源: %s  →  生成: %s" % [descriptor.source_tres, descriptor.output_path]
	)


func _selected_entry_index() -> int:
	var selected := _entry_tree.get_selected()
	if selected == null:
		return -1
	var meta: Variant = selected.get_metadata(0)
	if meta is Dictionary and meta.has(_TREE_META_INDEX):
		return int(meta[_TREE_META_INDEX])
	return -1


func _persist_active() -> RegistryResult:
	var descriptor := _active_descriptor()
	var registry := _active_registry()
	if descriptor == null or registry == null:
		return RegistryResult.err("无活动注册表")
	return _service.save_registry(descriptor, registry, false)


func _on_add_pressed() -> void:
	var descriptor := _active_descriptor()
	var registry := _active_registry()
	if descriptor == null or registry == null:
		return
	var entry_res := _service.create_entry(descriptor)
	if entry_res.is_err():
		RegistryLogger.error(str(entry_res.error))
		return
	var add_res := _service.add_entry(registry, entry_res.value)
	if add_res.is_err():
		RegistryLogger.error(str(add_res.error))
		return
	var save_res := _persist_active()
	if save_res.is_err():
		RegistryLogger.error(str(save_res.error))
		return
	_reload_tree()
	_status_label.text = "Added"


func _on_remove_pressed() -> void:
	var descriptor := _active_descriptor()
	var registry := _active_registry()
	var index := _selected_entry_index()
	if descriptor == null or registry == null or index < 0:
		return
	var remove_res := _service.remove_entry_at(registry, index)
	if remove_res.is_err():
		RegistryLogger.error(str(remove_res.error))
		return
	var save_res := _persist_active()
	if save_res.is_err():
		RegistryLogger.error(str(save_res.error))
		return
	_reload_tree()
	_status_label.text = "Removed"


func _on_open_tres_pressed() -> void:
	var descriptor := _active_descriptor()
	if descriptor == null:
		return
	var registry := _active_registry()
	if registry != null:
		EditorInterface.edit_resource(registry)
		return
	EditorInterface.get_resource_filesystem().update_file(descriptor.source_tres)


func _on_generate_pressed() -> void:
	if _service == null:
		return
	_status_label.text = "Generating..."
	_generate_button.disabled = true
	var res := _service.generate_all()
	_generate_button.disabled = false
	if res.is_err():
		_status_label.text = "Error"
		RegistryLogger.error(str(res.error))
		return
	_status_label.text = "Ready"
	RegistryLogger.info("Generation complete.")


func set_status(p_text: String) -> void:
	_status_label.text = p_text
#endregion
