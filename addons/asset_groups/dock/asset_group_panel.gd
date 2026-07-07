@tool
extends HSplitContainer

## Assets 页组件:左侧分组文件夹树([AssetGroupTree])+ 右侧选中资产的编辑表单。
##
## 分组的建/重命名/删除只在这里发生。Scenes 页的 asset_group 下拉框只读取
## manifest.collect_groups() 展示可选项,不管理分组本身——组名只有这一个管理
## 入口,不会两边各建一份、还要互相同步。

signal changed

const _UNGROUPED_LABEL := "— ungrouped —"
const _NONE_GROUP_ITEM := "— none —"

@onready var _tree: AssetGroupTree = %GroupTree
@onready var _add_id_button: Button = %AddIdButton
@onready var _add_group_button: Button = %AddGroupButton
@onready var _detail_panel: PanelContainer = %DetailPanel
@onready var _detail: VBoxContainer = %Detail
@onready var _id_edit: LineEdit = %IdEdit
@onready var _path_edit: LineEdit = %PathEdit
@onready var _browse_button: Button = %BrowseButton
@onready var _group_option: OptionButton = %GroupOption
@onready var _drag_hint_panel: PanelContainer = %DragHintPanel
@onready var _remove_button: Button = %RemoveButton

var _manifest: AssetManifest
var _selected_asset_id: StringName = &""
var _syncing_form := false
var _selected_tree_item: TreeItem
var _path_dialog: EditorFileDialog
var _new_group_dialog: AcceptDialog
var _new_group_edit: LineEdit
var _rename_group_dialog: AcceptDialog
var _rename_group_edit: LineEdit
var _context_menu: PopupMenu
var _context_menu_target := ""


func _ready() -> void:
	_path_dialog = EditorFileDialog.new()
	_path_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_path_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_path_dialog.file_selected.connect(_on_path_picked)
	add_child(_path_dialog)

	_new_group_edit = LineEdit.new()
	AssetGroupsStyle.configure_group_name_edit(_new_group_edit)
	_new_group_dialog = AcceptDialog.new()
	_new_group_dialog.title = "New asset group"
	_new_group_dialog.add_child(_new_group_edit)
	_new_group_dialog.confirmed.connect(_on_new_group_confirmed)
	add_child(_new_group_dialog)

	_rename_group_edit = LineEdit.new()
	AssetGroupsStyle.configure_group_name_edit(_rename_group_edit)
	_rename_group_dialog = AcceptDialog.new()
	_rename_group_dialog.title = "Rename group"
	_rename_group_dialog.add_child(_rename_group_edit)
	_rename_group_dialog.confirmed.connect(_on_rename_confirmed)
	add_child(_rename_group_dialog)

	_context_menu = PopupMenu.new()
	_context_menu.id_pressed.connect(_on_context_menu_id_pressed)
	add_child(_context_menu)

	_add_id_button.icon = get_theme_icon("Add", "EditorIcons")
	_add_group_button.icon = get_theme_icon("Folder", "EditorIcons")
	_remove_button.icon = get_theme_icon("Remove", "EditorIcons")
	_browse_button.icon = get_theme_icon("Folder", "EditorIcons")

	AssetGroupsStyle.configure_id_edit(_id_edit)
	AssetGroupsStyle.configure_path_edit(_path_edit)

	_detail_panel.add_theme_stylebox_override("panel", AssetGroupsStyle.card_panel(self))
	var selected_style := AssetGroupsStyle.selected_row(self)
	_tree.add_theme_stylebox_override("selected", selected_style)
	_tree.add_theme_stylebox_override("selected_focus", selected_style)
	_drag_hint_panel.add_theme_stylebox_override("panel", AssetGroupsStyle.hint_panel(self))
	_remove_button.add_theme_stylebox_override("normal", AssetGroupsStyle.outline_button(self, "error_color"))
	_remove_button.add_theme_color_override("font_color", get_theme_color("error_color", "Editor"))

	_tree.item_selected.connect(_on_tree_item_selected)
	_tree.item_mouse_selected.connect(_on_tree_mouse_selected)
	_tree.reassign_requested.connect(_on_reassign_requested)
	_add_id_button.pressed.connect(_on_add_id_pressed)
	_add_group_button.pressed.connect(func() -> void:
		_new_group_edit.text = ""
		_new_group_dialog.popup_centered())
	_id_edit.text_changed.connect(_on_id_changed)
	_path_edit.text_changed.connect(_on_path_changed)
	_browse_button.pressed.connect(func() -> void: _path_dialog.popup_centered_ratio())
	_group_option.item_selected.connect(_on_group_option_selected)
	_remove_button.pressed.connect(_on_remove_pressed)
	_detail_panel.hide()


func set_manifest(manifest: AssetManifest) -> void:
	_manifest = manifest
	refresh()


## 整棵树全量重建(分组数量通常很小,重建成本可以忽略),尽量保留选中项。
func refresh() -> void:
	var keep_id := _selected_asset_id

	_tree.clear()
	var root := _tree.create_item()
	_tree.hide_root = true

	var group_row_color := get_theme_color("dark_color_1", "Editor")
	var found_item: TreeItem
	for group_name in _manifest.collect_groups():
		var g_item := _tree.create_item(root)
		var group_assets := _manifest.assets_in_group(StringName(group_name))
		g_item.set_text(0, group_name if not group_assets.is_empty() else "%s (empty)" % group_name)
		g_item.set_custom_bg_color(0, group_row_color)
		for entry in group_assets:
			var a_item := _tree.create_item(g_item)
			a_item.set_text(0, String(entry.id) if entry.id != &"" else "(unnamed)")
			a_item.set_metadata(0, entry.id)
			if entry.id == keep_id and keep_id != &"":
				found_item = a_item

	var ungrouped := _manifest.assets_in_group(&"")
	if not ungrouped.is_empty():
		var u_item := _tree.create_item(root)
		u_item.set_text(0, _UNGROUPED_LABEL)
		u_item.set_custom_bg_color(0, group_row_color)
		for entry in ungrouped:
			var a_item := _tree.create_item(u_item)
			a_item.set_text(0, String(entry.id) if entry.id != &"" else "(unnamed)")
			a_item.set_metadata(0, entry.id)
			if entry.id == keep_id and keep_id != &"":
				found_item = a_item

	if found_item != null:
		found_item.select(0)
		_selected_tree_item = found_item
		_selected_asset_id = keep_id
		_populate_detail(_manifest.find_asset(keep_id))
	else:
		_selected_tree_item = null
		_selected_asset_id = &""
		_detail_panel.hide()


func _on_tree_item_selected() -> void:
	var item := _tree.get_selected()
	var meta: Variant = item.get_metadata(0)
	if meta == null:
		_selected_tree_item = null
		_selected_asset_id = &""
		_detail_panel.hide()
		return
	_selected_tree_item = item
	_selected_asset_id = meta
	_populate_detail(_manifest.find_asset(_selected_asset_id))


func _populate_detail(entry: AssetEntry) -> void:
	if entry == null:
		_detail_panel.hide()
		return
	_detail_panel.show()
	_syncing_form = true
	EntryPathUtils.set_line_edit_text(_id_edit, String(entry.id))
	EntryPathUtils.set_line_edit_text(_path_edit, entry.path)
	_syncing_form = false

	_group_option.clear()
	_group_option.add_item(_NONE_GROUP_ITEM)
	_group_option.set_item_metadata(0, "")
	var idx := 1
	var selected_idx := 0
	for group_name in _manifest.collect_groups():
		_group_option.add_item(group_name)
		_group_option.set_item_metadata(idx, group_name)
		if group_name == String(entry.group):
			selected_idx = idx
		idx += 1
	_group_option.select(selected_idx)


## 决定"新加的 id 该落进哪个分组"：选中分组节点就用它,选中资产节点就用它所在的
## 分组,什么都没选就落进 &"core"。
func _current_group_context() -> String:
	var item := _tree.get_selected()
	if item == null:
		return "core"
	if item.get_metadata(0) == null:
		var text := item.get_text(0).trim_suffix(" (empty)")
		if text == _UNGROUPED_LABEL:
			return ""
		return text
	return _group_label_from_item(item.get_parent())


func _on_add_id_pressed() -> void:
	var group_name := _current_group_context()
	var entry := AssetEntry.new()
	entry.id = _unique_id("new_asset")
	entry.group = StringName(group_name)
	_manifest.assets.append(entry)
	_selected_asset_id = entry.id
	refresh()
	changed.emit()


func _unique_id(base: String) -> StringName:
	var n := 1
	var candidate := base
	while _manifest.find_asset(StringName(candidate)) != null:
		n += 1
		candidate = "%s_%d" % [base, n]
	return StringName(candidate)


func _on_id_changed(text: String) -> void:
	if _syncing_form or _selected_asset_id == &"":
		return
	var entry := _manifest.find_asset(_selected_asset_id)
	entry.id = StringName(text)
	_selected_asset_id = entry.id
	if _selected_tree_item != null:
		_selected_tree_item.set_text(0, text if text != "" else "(unnamed)")
		_selected_tree_item.set_metadata(0, entry.id)
	changed.emit()


func _on_path_changed(text: String) -> void:
	if _syncing_form or _selected_asset_id == &"":
		return
	var entry := _manifest.find_asset(_selected_asset_id)
	if entry == null:
		return
	entry.path = text
	changed.emit()


func _on_path_picked(path: String) -> void:
	_apply_path_from_picker(path)


func _apply_path_from_picker(path: String) -> void:
	if _selected_asset_id == &"":
		return
	var entry := _manifest.find_asset(_selected_asset_id)
	if entry == null:
		return
	entry.path = path
	if not path.is_empty():
		entry.id = EntryPathUtils.unique_id(EntryPathUtils.basename_id(path), func(id: StringName) -> bool:
			var other := _manifest.find_asset(id)
			return other != null and other != entry
		)
		_selected_asset_id = entry.id
	_syncing_form = true
	EntryPathUtils.set_line_edit_text(_path_edit, path)
	EntryPathUtils.set_line_edit_text(_id_edit, String(entry.id))
	_syncing_form = false
	if _selected_tree_item != null:
		_selected_tree_item.set_text(0, String(entry.id) if entry.id != &"" else "(unnamed)")
		_selected_tree_item.set_metadata(0, entry.id)
	changed.emit()


func _on_group_option_selected(index: int) -> void:
	if _selected_asset_id == &"":
		return
	var group_name := String(_group_option.get_item_metadata(index))
	_manifest.find_asset(_selected_asset_id).group = StringName(group_name)
	refresh()
	changed.emit()


func _on_new_group_confirmed() -> void:
	var group_name := _new_group_edit.text.strip_edges()
	if group_name == "":
		return
	_manifest.add_group(StringName(group_name))
	refresh()
	changed.emit()


func _on_tree_mouse_selected(position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_RIGHT:
		return
	var item := _tree.get_item_at_position(position)
	if item == null or item.get_metadata(0) != null:
		return
	var group_name := item.get_text(0).trim_suffix(" (empty)")
	if group_name == "core" or group_name == _UNGROUPED_LABEL:
		return
	_context_menu_target = group_name
	_context_menu.clear()
	_context_menu.add_item("Rename group", 0)
	_context_menu.add_item("Delete group", 1)
	_context_menu.position = DisplayServer.mouse_get_position()
	_context_menu.popup()


func _on_context_menu_id_pressed(id: int) -> void:
	match id:
		0:
			_rename_group_edit.text = _context_menu_target
			_rename_group_dialog.popup_centered()
		1:
			_manifest.remove_group(StringName(_context_menu_target))
			refresh()
			changed.emit()


func _on_rename_confirmed() -> void:
	var new_name := _rename_group_edit.text.strip_edges()
	if new_name == "" or new_name == _context_menu_target:
		return
	_manifest.rename_group(StringName(_context_menu_target), StringName(new_name))
	refresh()
	changed.emit()


func _on_reassign_requested(asset_id: StringName, group_name: StringName) -> void:
	var entry := _manifest.find_asset(asset_id)
	if entry == null:
		return
	entry.group = &"" if String(group_name) == _UNGROUPED_LABEL else group_name
	refresh()
	changed.emit()


func _on_remove_pressed() -> void:
	if _selected_asset_id == &"":
		return
	var entry := _manifest.find_asset(_selected_asset_id)
	_manifest.assets.erase(entry)
	_selected_asset_id = &""
	refresh()
	changed.emit()


func _group_label_from_item(item: TreeItem) -> String:
	var text := item.get_text(0).trim_suffix(" (empty)")
	return "" if text == _UNGROUPED_LABEL else text
