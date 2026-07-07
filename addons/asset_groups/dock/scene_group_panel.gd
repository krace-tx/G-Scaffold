@tool
extends HSplitContainer

## Scenes 页组件:左侧场景 id 列表 + 右侧选中条目的编辑表单。
## 只认外部通过 [method set_manifest] 传入的 [AssetManifest],不持有自己的持久化状态;
## 编辑直接改 manifest.scenes 里的 [SceneEntry] 实例(Resource 是引用类型,原地生效)。

signal changed

const _NEW_GROUP_SENTINEL := "+ New group…"

@onready var _id_list: ItemList = %IdList
@onready var _add_button: Button = %AddButton
@onready var _detail_panel: PanelContainer = %DetailPanel
@onready var _detail: VBoxContainer = %Detail
@onready var _id_edit: LineEdit = %IdEdit
@onready var _path_edit: LineEdit = %ScenePathEdit
@onready var _browse_button: Button = %BrowseButton
@onready var _quick_open_button: Button = %QuickOpenButton
@onready var _group_option: OptionButton = %AssetGroupOption
@onready var _remove_button: Button = %RemoveButton

var _manifest: AssetManifest
var _selected_index := -1
var _syncing_form := false
var _path_dialog: EditorFileDialog
var _new_group_dialog: AcceptDialog
var _new_group_edit: LineEdit


func _ready() -> void:
	_path_dialog = EditorFileDialog.new()
	_path_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_path_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_path_dialog.filters = PackedStringArray(["*.tscn ; Scenes"])
	_path_dialog.file_selected.connect(_on_path_picked)
	add_child(_path_dialog)

	_new_group_edit = LineEdit.new()
	AssetGroupsStyle.configure_group_name_edit(_new_group_edit)
	_new_group_dialog = AcceptDialog.new()
	_new_group_dialog.title = "New asset group"
	_new_group_dialog.add_child(_new_group_edit)
	_new_group_dialog.confirmed.connect(_on_new_group_confirmed)
	add_child(_new_group_dialog)

	_add_button.icon = get_theme_icon("Add", "EditorIcons")
	_remove_button.icon = get_theme_icon("Remove", "EditorIcons")
	_browse_button.icon = get_theme_icon("Folder", "EditorIcons")
	_quick_open_button.icon = get_theme_icon("Search", "EditorIcons")

	AssetGroupsStyle.configure_id_edit(_id_edit)
	AssetGroupsStyle.configure_path_edit(_path_edit)

	_detail_panel.add_theme_stylebox_override("panel", AssetGroupsStyle.card_panel(self))
	var selected_style := AssetGroupsStyle.selected_row(self)
	_id_list.add_theme_stylebox_override("selected", selected_style)
	_id_list.add_theme_stylebox_override("selected_focus", selected_style)
	_remove_button.add_theme_stylebox_override("normal", AssetGroupsStyle.outline_button(self, "error_color"))
	_remove_button.add_theme_color_override("font_color", get_theme_color("error_color", "Editor"))

	_add_button.pressed.connect(_on_add_pressed)
	_id_list.item_selected.connect(_on_item_selected)
	_id_edit.text_changed.connect(_on_id_changed)
	_path_edit.text_changed.connect(_on_path_changed)
	_browse_button.pressed.connect(func() -> void: _path_dialog.popup_centered_ratio())
	_quick_open_button.pressed.connect(_on_quick_open_pressed)
	_group_option.item_selected.connect(_on_group_selected)
	_remove_button.pressed.connect(_on_remove_pressed)
	_detail_panel.hide()


func set_manifest(manifest: AssetManifest) -> void:
	_manifest = manifest
	refresh()


## 重建列表与分组下拉;尽量保留原有选中项(按 id 找,找不到就清空详情面板)。
func refresh() -> void:
	var keep_id: StringName = &""
	if _selected_index >= 0 and _selected_index < _manifest.scenes.size():
		keep_id = _manifest.scenes[_selected_index].id

	_id_list.clear()
	for entry in _manifest.scenes:
		_id_list.add_item(String(entry.id) if entry.id != &"" else "(unnamed)")

	_selected_index = -1
	if keep_id != &"":
		for i in _manifest.scenes.size():
			if _manifest.scenes[i].id == keep_id:
				_selected_index = i
				break

	if _selected_index >= 0:
		_id_list.select(_selected_index)
		_populate_detail(_manifest.scenes[_selected_index])
	else:
		_detail_panel.hide()


func _on_add_pressed() -> void:
	var entry := SceneEntry.new()
	entry.id = _unique_id("new_scene")
	_manifest.scenes.append(entry)
	var new_index := _manifest.scenes.size() - 1
	refresh()
	_id_list.select(new_index)
	_on_item_selected(new_index)
	changed.emit()


func _unique_id(base: String) -> StringName:
	var n := 1
	var candidate := base
	while _manifest.find_scene(StringName(candidate)) != null:
		n += 1
		candidate = "%s_%d" % [base, n]
	return StringName(candidate)


func _on_item_selected(index: int) -> void:
	_selected_index = index
	_populate_detail(_manifest.scenes[index])


func _populate_detail(entry: SceneEntry) -> void:
	_detail_panel.show()
	_syncing_form = true
	EntryPathUtils.set_line_edit_text(_id_edit, String(entry.id))
	EntryPathUtils.set_line_edit_text(_path_edit, entry.scene_path)
	_syncing_form = false

	_group_option.clear()
	_group_option.add_item("— none —")
	_group_option.set_item_metadata(0, "")
	var idx := 1
	var selected_idx := 0
	for group_name in _manifest.collect_groups():
		_group_option.add_item(group_name)
		_group_option.set_item_metadata(idx, group_name)
		if group_name == String(entry.asset_group):
			selected_idx = idx
		idx += 1
	_group_option.add_item(_NEW_GROUP_SENTINEL)
	_group_option.select(selected_idx)


func _on_id_changed(text: String) -> void:
	if _syncing_form or _selected_index < 0:
		return
	_manifest.scenes[_selected_index].id = StringName(text)
	_id_list.set_item_text(_selected_index, text if text != "" else "(unnamed)")
	changed.emit()


func _on_path_changed(text: String) -> void:
	if _syncing_form or _selected_index < 0:
		return
	_manifest.scenes[_selected_index].scene_path = text
	changed.emit()


func _on_path_picked(path: String) -> void:
	_apply_path_from_picker(path)


func _apply_path_from_picker(path: String) -> void:
	if _selected_index < 0:
		return
	var entry := _manifest.scenes[_selected_index]
	entry.scene_path = path
	if not path.is_empty():
		entry.id = EntryPathUtils.unique_id(EntryPathUtils.basename_id(path), func(id: StringName) -> bool:
			var other := _manifest.find_scene(id)
			return other != null and other != entry
		)
	_syncing_form = true
	EntryPathUtils.set_line_edit_text(_path_edit, path)
	EntryPathUtils.set_line_edit_text(_id_edit, String(entry.id))
	_syncing_form = false
	_id_list.set_item_text(_selected_index, String(entry.id) if entry.id != &"" else "(unnamed)")
	changed.emit()


## Godot 自带的 Ctrl+Shift+O 同款模糊搜索弹窗,比文件树浏览快很多——不用一层层
## 展开目录,直接敲关键字过滤全项目的场景文件。
func _on_quick_open_pressed() -> void:
	EditorInterface.popup_quick_open(_on_path_picked, [&"PackedScene"])


func _on_group_selected(index: int) -> void:
	if _selected_index < 0:
		return
	var text := _group_option.get_item_text(index)
	if text == _NEW_GROUP_SENTINEL:
		_new_group_edit.text = ""
		_new_group_dialog.popup_centered()
		return
	_manifest.scenes[_selected_index].asset_group = StringName(_group_option.get_item_metadata(index) as String)
	changed.emit()


func _on_new_group_confirmed() -> void:
	if _selected_index < 0:
		return
	var group_name := _new_group_edit.text.strip_edges()
	if group_name == "":
		return
	_manifest.add_group(StringName(group_name))
	_manifest.scenes[_selected_index].asset_group = StringName(group_name)
	changed.emit()
	_populate_detail(_manifest.scenes[_selected_index])


func _on_remove_pressed() -> void:
	if _selected_index < 0:
		return
	_manifest.scenes.remove_at(_selected_index)
	_selected_index = -1
	refresh()
	changed.emit()
