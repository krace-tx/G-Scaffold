@tool
extends HSplitContainer

## UI 页组件:左侧 UI id 列表 + 右侧选中条目的编辑表单(Layer/Cache 用下拉,
## 选项直接从运行时对齐过的 [UIEntry.Layer]/[UIEntry.Cache] 枚举生成,下拉的
## item 下标天然等于枚举值,不需要额外的 metadata 映射)。

signal changed

@onready var _id_list: ItemList = %IdList
@onready var _add_button: Button = %AddButton
@onready var _empty_state: Control = %EmptyState
@onready var _detail_panel: PanelContainer = %DetailPanel
@onready var _detail: VBoxContainer = %Detail
@onready var _id_edit: LineEdit = %IdEdit
@onready var _path_edit: EntryPathLineEdit = %ScenePathEdit
@onready var _browse_button: Button = %BrowseButton
@onready var _quick_open_button: Button = %QuickOpenButton
@onready var _layer_option: OptionButton = %LayerOption
@onready var _cache_option: OptionButton = %CacheOption
@onready var _remove_button: Button = %RemoveButton

var _manifest: AssetManifest
var _selected_index := -1
var _syncing_form := false
var _path_dialog: EditorFileDialog


func _ready() -> void:
	_path_dialog = EditorFileDialog.new()
	_path_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_path_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_path_dialog.filters = EntryPathUtils.file_dialog_filters(EntryPathUtils.SCENE_EXTENSIONS)
	_path_dialog.file_selected.connect(_on_path_picked)
	add_child(_path_dialog)

	for key in UIEntry.Layer.keys():
		_layer_option.add_item(key.to_lower())
	for key in UIEntry.Cache.keys():
		_cache_option.add_item(key.to_lower())

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
	_path_edit.path_dropped.connect(_on_path_picked)
	_browse_button.pressed.connect(func() -> void: _path_dialog.popup_centered_ratio())
	_quick_open_button.pressed.connect(_on_quick_open_pressed)
	_layer_option.item_selected.connect(_on_layer_selected)
	_cache_option.item_selected.connect(_on_cache_selected)
	_remove_button.pressed.connect(_on_remove_pressed)
	_empty_state.setup(
		self,
		"Control",
		"No UI selected",
		"Pick an entry from the list to edit id, scene path, layer and cache.",
		PackedStringArray([
			"Press + to add a new UI id",
			"Drag a .tscn from FileSystem onto the path field",
			"Layer controls which UI stack the panel belongs to",
			"Cache policy decides whether the panel is kept in memory",
		])
	)
	_show_empty_state()


func set_manifest(manifest: AssetManifest) -> void:
	_manifest = manifest
	refresh()


func refresh() -> void:
	var keep_id: StringName = &""
	if _selected_index >= 0 and _selected_index < _manifest.uis.size():
		keep_id = _manifest.uis[_selected_index].id

	_id_list.clear()
	for entry in _manifest.uis:
		_id_list.add_item(String(entry.id) if entry.id != &"" else "(unnamed)")

	_selected_index = -1
	if keep_id != &"":
		for i in _manifest.uis.size():
			if _manifest.uis[i].id == keep_id:
				_selected_index = i
				break

	if _selected_index >= 0:
		_id_list.select(_selected_index)
		_populate_detail(_manifest.uis[_selected_index])
	else:
		_show_empty_state()


func _show_empty_state() -> void:
	_detail.hide()
	_empty_state.show()


func _show_detail() -> void:
	_empty_state.hide()
	_detail.show()


func _on_add_pressed() -> void:
	var entry := UIEntry.new()
	entry.id = _unique_id("new_ui")
	_manifest.uis.append(entry)
	var new_index := _manifest.uis.size() - 1
	refresh()
	_id_list.select(new_index)
	_on_item_selected(new_index)
	changed.emit()


func _unique_id(base: String) -> StringName:
	var n := 1
	var candidate := base
	while _manifest.find_ui(StringName(candidate)) != null:
		n += 1
		candidate = "%s_%d" % [base, n]
	return StringName(candidate)


func _on_item_selected(index: int) -> void:
	_selected_index = index
	_populate_detail(_manifest.uis[index])


func _populate_detail(entry: UIEntry) -> void:
	_show_detail()
	_syncing_form = true
	EntryPathUtils.set_line_edit_text(_id_edit, String(entry.id))
	EntryPathUtils.set_line_edit_text(_path_edit, entry.scene_path)
	_syncing_form = false
	_layer_option.select(entry.layer)
	_cache_option.select(entry.cache)


func _on_id_changed(text: String) -> void:
	if _syncing_form or _selected_index < 0:
		return
	_manifest.uis[_selected_index].id = StringName(text)
	_id_list.set_item_text(_selected_index, text if text != "" else "(unnamed)")
	changed.emit()


func _on_path_changed(text: String) -> void:
	if _syncing_form or _selected_index < 0:
		return
	_manifest.uis[_selected_index].scene_path = text
	changed.emit()


func _on_path_picked(path: String) -> void:
	_apply_path_from_picker(path)


func _apply_path_from_picker(path: String) -> void:
	if _selected_index < 0:
		return
	var entry := _manifest.uis[_selected_index]
	entry.scene_path = path
	entry.id = EntryPathUtils.resolve_id_after_path_pick(path, entry.id, func(id: StringName) -> bool:
		var other := _manifest.find_ui(id)
		return other != null and other != entry
	)
	_syncing_form = true
	EntryPathUtils.set_line_edit_text(_path_edit, path)
	EntryPathUtils.set_line_edit_text(_id_edit, String(entry.id))
	_syncing_form = false
	_id_list.set_item_text(_selected_index, String(entry.id) if entry.id != &"" else "(unnamed)")
	changed.emit()


## Godot 自带的 Ctrl+Shift+O 同款模糊搜索弹窗,比文件树浏览快很多。
func _on_quick_open_pressed() -> void:
	EditorInterface.popup_quick_open(_on_path_picked, [&"PackedScene"])


func _on_layer_selected(index: int) -> void:
	if _selected_index < 0:
		return
	_manifest.uis[_selected_index].layer = index as UIEntry.Layer
	changed.emit()


func _on_cache_selected(index: int) -> void:
	if _selected_index < 0:
		return
	_manifest.uis[_selected_index].cache = index as UIEntry.Cache
	changed.emit()


func _on_remove_pressed() -> void:
	if _selected_index < 0:
		return
	_manifest.uis.remove_at(_selected_index)
	_selected_index = -1
	refresh()
	changed.emit()
