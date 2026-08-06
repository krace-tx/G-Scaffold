@tool
class_name ResourceGroupDetailPresenter
extends RefCounted

signal resource_id_edited(res_id: StringName, new_text: String)
signal resource_path_edited(res_id: StringName, path: String)
signal resource_group_edited(res_id: StringName, group_name: String)
signal resource_path_picked(res_id: StringName, path: String)
signal group_rename_submitted(group_name: StringName, new_text: String)
signal remove_requested()
signal group_remove_requested(group_name: StringName)

# --- UI 节点引用 (通过 bind 注入) ---
var _host: Control
var _empty_state: Control
var _detail_panel: PanelContainer
var _group_detail: VBoxContainer
var _group_name_edit: LineEdit
var _multi_detail: VBoxContainer
var _multi_count_label: Label
var _multi_remove_button: Button
var _detail: VBoxContainer
var _id_edit: LineEdit
var _path_edit: EntryPathLineEdit
var _browse_button: Button
var _group_option: OptionButton
var _drag_hint_panel: PanelContainer
var _remove_button: Button
var _group_remove_button: Button
var _path_dialog: EditorFileDialog

# --- 核心状态 ---
var _manifest: EditAssetManifest
var _active_resource_id: StringName = &""
var _active_group: StringName = ResourceGroupConstants.NO_GROUP_SELECTED

var _syncing_form := false


func bind(
	host: Control,
	empty_state: Control,
	detail_panel: PanelContainer,
	group_detail: VBoxContainer,
	group_name_edit: LineEdit,
	multi_detail: VBoxContainer,
	multi_count_label: Label,
	multi_remove_button: Button,
	detail: VBoxContainer,
	id_edit: LineEdit,
	path_edit: EntryPathLineEdit,
	browse_button: Button,
	group_option: OptionButton,
	drag_hint_panel: PanelContainer,
	remove_button: Button,
	group_remove_button: Button
) -> void:
	_host = host
	_empty_state = empty_state
	_detail_panel = detail_panel
	_group_detail = group_detail
	_group_name_edit = group_name_edit
	_multi_detail = multi_detail
	_multi_count_label = multi_count_label
	_multi_remove_button = multi_remove_button
	_detail = detail
	_id_edit = id_edit
	_path_edit = path_edit
	_browse_button = browse_button
	_group_option = group_option
	_drag_hint_panel = drag_hint_panel
	_remove_button = remove_button
	_group_remove_button = group_remove_button

	_setup_style()
	_setup_path_dialog()
	_setup_empty_state()
	_connect_signals()


func set_manifest(manifest: EditAssetManifest) -> void:
	_manifest = manifest


func render(snapshot: ResourceGroupSelection) -> void:
	match snapshot.mode:
		ResourceGroupSelection.Mode.EMPTY:
			_active_resource_id = &""
			_active_group = ResourceGroupConstants.NO_GROUP_SELECTED
			show_empty()
		ResourceGroupSelection.Mode.SINGLE_RESOURCE:
			_active_group = ResourceGroupConstants.NO_GROUP_SELECTED
			show_resource(snapshot.resource_id)
		ResourceGroupSelection.Mode.MULTI_RESOURCE:
			_active_resource_id = &""
			_active_group = ResourceGroupConstants.NO_GROUP_SELECTED
			show_multi(snapshot.resource_ids.size())
		ResourceGroupSelection.Mode.GROUP:
			_active_resource_id = &""
			show_group(snapshot.group_name)


func show_empty() -> void:
	_detail.hide()
	_group_detail.hide()
	_multi_detail.hide()
	_empty_state.show()
	_empty_state.set_message(
		_host,
		"Folder",
		"No resource or group selected",
		"Pick a group folder to rename, delete, or add a child group.",
		_default_hints()
	)


func show_multi(count: int) -> void:
	_empty_state.hide()
	_detail.hide()
	_group_detail.hide()
	_multi_detail.show()
	_multi_count_label.text = "%d resources selected" % count
	_multi_remove_button.text = "Remove %d resources" % count


func show_group(group_name: StringName) -> void:
	if group_name == ResourceGroupConstants.NO_GROUP_SELECTED:
		show_empty()
		return

	_active_group = group_name
	_empty_state.hide()
	_detail.hide()
	_multi_detail.hide()
	_group_detail.show()

	_syncing_form = true
	var can_rename: bool = group_name != &""
	_group_name_edit.editable = can_rename
	_group_name_edit.text = (
		ResourceGroupConstants.UNGROUPED_LABEL if group_name == &"" else String(group_name)
	)
	_group_remove_button.visible = can_rename
	_syncing_form = false


func show_resource(res_id: StringName) -> void:
	var entry := _manifest.find_resource(res_id) if _manifest != null else null
	if entry == null:
		show_empty()
		return

	_active_resource_id = res_id
	_empty_state.hide()
	_group_detail.hide()
	_multi_detail.hide()
	_detail.show()

	_syncing_form = true
	EntryPathUtils.set_line_edit_text(_id_edit, String(entry.id))
	EntryPathUtils.set_line_edit_text(_path_edit, entry.path)
	_syncing_form = false

	_populate_group_option(entry)


func set_group_rename_text(text: String) -> void:
	_group_name_edit.text = text


func active_resource_id() -> StringName:
	return _active_resource_id


func active_group_name() -> StringName:
	return _active_group


func _setup_style() -> void:
	AssetGroupsEditorTheme.apply_asset_detail(
		_host,
		_detail_panel,
		_drag_hint_panel,
		_remove_button,
		_multi_remove_button,
		_browse_button
	)
	AssetGroupsEditorTheme.apply_danger_button(_host, _group_remove_button)


func _setup_path_dialog() -> void:
	_path_dialog = EditorFileDialog.new()
	_path_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_path_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_path_dialog.filters = EntryPathUtils.file_dialog_filters(EntryPathUtils.ASSET_EXTENSIONS)
	_path_dialog.file_selected.connect(_on_path_dialog_file_selected)
	_host.add_child(_path_dialog)


func _setup_empty_state() -> void:
	_empty_state.setup(
		_host,
		"Folder",
		"No resource or group selected",
		"Pick a group folder to rename, delete, or add a child group.",
		_default_hints()
	)


func _connect_signals() -> void:
	_id_edit.text_changed.connect(_on_id_changed)
	_path_edit.text_changed.connect(_on_path_changed)
	_path_edit.path_dropped.connect(_on_path_dropped)
	_browse_button.pressed.connect(func() -> void: _path_dialog.popup_centered_ratio())
	_group_option.item_selected.connect(_on_group_option_selected)
	_group_name_edit.text_submitted.connect(_on_group_name_submitted)
	_group_name_edit.focus_exited.connect(_on_group_name_focus_exited)
	_remove_button.pressed.connect(func() -> void: remove_requested.emit())
	_multi_remove_button.pressed.connect(func() -> void: remove_requested.emit())
	_group_remove_button.pressed.connect(func() -> void: group_remove_requested.emit(_active_group))


func _populate_group_option(entry: EditResourceEntry) -> void:
	_syncing_form = true
	_group_option.clear()
	_group_option.add_item(ResourceGroupConstants.NONE_GROUP_ITEM)
	_group_option.set_item_metadata(0, "")

	var idx := 1
	var selected_idx := 0
	for group_name in _manifest.collect_resource_groups():
		_group_option.add_item(group_name)
		_group_option.set_item_metadata(idx, group_name)
		if group_name == String(entry.group):
			selected_idx = idx
		idx += 1

	_group_option.select(selected_idx)
	_syncing_form = false


func _on_id_changed(text: String) -> void:
	if _syncing_form or _active_resource_id == &"":
		return
	resource_id_edited.emit(_active_resource_id, text)


func _on_path_changed(text: String) -> void:
	if _syncing_form or _active_resource_id == &"":
		return
	resource_path_edited.emit(_active_resource_id, text)


func _on_path_dropped(path: String) -> void:
	if _active_resource_id == &"":
		return
	resource_path_picked.emit(_active_resource_id, path)


func _on_path_dialog_file_selected(path: String) -> void:
	if _active_resource_id == &"":
		return
	resource_path_picked.emit(_active_resource_id, path)


func _on_group_option_selected(index: int) -> void:
	if _syncing_form or _active_resource_id == &"":
		return
	var group_name := String(_group_option.get_item_metadata(index))
	resource_group_edited.emit(_active_resource_id, group_name)


func _on_group_name_submitted(_new_text: String) -> void:
	_submit_group_rename()


func _on_group_name_focus_exited() -> void:
	_submit_group_rename()


func _submit_group_rename() -> void:
	if _active_group == ResourceGroupConstants.NO_GROUP_SELECTED or _syncing_form:
		return
	group_rename_submitted.emit(_active_group, _group_name_edit.text)


func _default_hints() -> PackedStringArray:
	return PackedStringArray([
		"Folder tree shows real directory names; Group values stay uppercase (ENTITIES_CONFIG)",
		"Right-click a folder to add a child group, rename, or delete",
		"Toolbar folder button creates a child group under the selected folder",
		"Ctrl+click or Shift+click to select multiple resources, then drag to a group",
		"Press + on the toolbar to add an id to the selected group",
		"Drag supported files from FileSystem onto the path field",
		"Drag resources between group folders to reorganize",
	])
