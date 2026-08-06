@tool
class_name AssetGroupDetailPresenter
extends RefCounted

## 右侧详情区调度器 (Presenter)。
## 负责管理详情面板的四种视图状态：空状态、单资产视图、多选视图、分组视图。
## 职责边界：只负责向外散发用户编辑意图（Signals），绝对不直接修改底层 Manifest 数据。

#region Signals
## 当用户修改单资产的 ID 时触发
signal asset_id_edited(asset_id: StringName, new_text: String)
## 当用户在输入框修改单资产的路径时触发
signal asset_path_edited(asset_id: StringName, path: String)
## 当用户通过下拉框修改单资产所属的分组时触发
signal asset_group_edited(asset_id: StringName, group_name: String)
## 当用户通过拖拽或文件对话框选中新路径时触发
signal asset_path_picked(asset_id: StringName, path: String)
## 当用户提交分组重命名时触发（回车或失去焦点）
signal group_rename_submitted(group_name: StringName, new_text: String)
## 当用户点击删除按钮（单选或多选视图下）时触发
signal remove_requested()
## 当用户点击删除分组按钮时触发
signal group_remove_requested(group_name: StringName)
#endregion

#region Exports & State
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
var _active_asset_id: StringName = &""
var _active_group: StringName = AssetGroupConstants.NO_GROUP_SELECTED

## 防御性状态标志：当由代码主动更新 UI 文本时设为 true，
## 拦截 text_changed 等信号，防止触发死循环或误报编辑事件。
var _syncing_form := false
#endregion

#region Public API
## 依赖注入：绑定所有需要的 UI 节点并初始化样式与事件监听。
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

## 注入数据源契约，用于查询资产详情和枚举可用分组。
func set_manifest(manifest: EditAssetManifest) -> void:
	_manifest = manifest

## 视图渲染总路由：根据传入的 Selection 快照，切换到对应的 UI 面板。
func render(snapshot: AssetGroupSelection) -> void:
	match snapshot.mode:
		AssetGroupSelection.Mode.EMPTY:
			_active_asset_id = &""
			_active_group = AssetGroupConstants.NO_GROUP_SELECTED
			show_empty()
		AssetGroupSelection.Mode.SINGLE_ASSET:
			_active_group = AssetGroupConstants.NO_GROUP_SELECTED
			show_asset(snapshot.asset_id)
		AssetGroupSelection.Mode.MULTI_ASSET:
			_active_asset_id = &""
			_active_group = AssetGroupConstants.NO_GROUP_SELECTED
			show_multi(snapshot.asset_ids.size())
		AssetGroupSelection.Mode.GROUP:
			_active_asset_id = &""
			show_group(snapshot.group_name)

## 切换至空状态视图（未选中任何内容）。
func show_empty() -> void:
	_detail.hide()
	_group_detail.hide()
	_multi_detail.hide()
	_empty_state.show()
	_empty_state.set_message(
		_host,
		"Folder",
		"No asset or group selected",
		"Pick a group folder to rename, delete, or add a child group.",
		_default_hints()
	)

## 切换至多选视图，显示当前选中的资源数量及批量操作按钮。
func show_multi(count: int) -> void:
	_empty_state.hide()
	_detail.hide()
	_group_detail.hide()
	_multi_detail.show()
	_multi_count_label.text = "%d assets selected" % count
	_multi_remove_button.text = "Remove %d assets" % count

## 切换至分组详情视图，允许重命名分组（排除核心内置分组）。
func show_group(group_name: StringName) -> void:
	if group_name == AssetGroupConstants.NO_GROUP_SELECTED:
		show_empty()
		return
		
	_active_group = group_name
	_empty_state.hide()
	_detail.hide()
	_multi_detail.hide()
	_group_detail.show()
	
	# 开启防重入锁，更新 UI 文本
	_syncing_form = true
	var can_rename: bool = group_name != &""
	_group_name_edit.editable = can_rename
	_group_name_edit.text = (
		AssetGroupConstants.UNGROUPED_LABEL if group_name == &"" else String(group_name)
	)
	_group_remove_button.visible = can_rename
	_syncing_form = false

## 切换至单资产视图，展示其 ID、路径和所属分组。
func show_asset(asset_id: StringName) -> void:
	var entry := _manifest.find_asset(asset_id) if _manifest != null else null
	if entry == null:
		show_empty()
		return
		
	_active_asset_id = asset_id
	_empty_state.hide()
	_group_detail.hide()
	_multi_detail.hide()
	_detail.show()
	
	# 开启防重入锁，防止 set_line_edit_text 触发 _on_id_changed 信号
	_syncing_form = true
	EntryPathUtils.set_line_edit_text(_id_edit, String(entry.id))
	EntryPathUtils.set_line_edit_text(_path_edit, entry.path)
	_syncing_form = false
	
	_populate_group_option(entry)

## 外部请求强制回写分组名称输入框。
func set_group_rename_text(text: String) -> void:
	_group_name_edit.text = text

func active_asset_id() -> StringName:
	return _active_asset_id

func active_group_name() -> StringName:
	return _active_group
#endregion

#region Lifecycle
## 利用代码注入 Theme 样式，确保插件的视觉一致性。
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

## 初始化文件选择对话框（用于浏览并替换资产路径）。
func _setup_path_dialog() -> void:
	_path_dialog = EditorFileDialog.new()
	_path_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_path_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_path_dialog.filters = EntryPathUtils.file_dialog_filters(EntryPathUtils.ASSET_EXTENSIONS)
	_path_dialog.file_selected.connect(_on_path_dialog_file_selected)
	_host.add_child(_path_dialog)

## 初始化空状态提示。
func _setup_empty_state() -> void:
	_empty_state.setup(
		_host,
		"Folder",
		"No asset or group selected",
		"Pick a group folder to rename, delete, or add a child group.",
		_default_hints()
	)

## 绑定所有 UI 交互事件。
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
#endregion

#region Internal
## 动态构建分组下拉列表，并选中当前资产所在的分组。
func _populate_group_option(entry: EditAssetEntry) -> void:
	_syncing_form = true
	_group_option.clear()
	_group_option.add_item(AssetGroupConstants.NONE_GROUP_ITEM)
	_group_option.set_item_metadata(0, "")
	
	var idx := 1
	var selected_idx := 0
	for group_name in _manifest.collect_asset_groups():
		_group_option.add_item(group_name)
		_group_option.set_item_metadata(idx, group_name)
		if group_name == String(entry.group):
			selected_idx = idx
		idx += 1
		
	_group_option.select(selected_idx)
	_syncing_form = false

# --- 以下为 UI 交互回调 ---

func _on_id_changed(text: String) -> void:
	# 如果是代码主动更新，拦截信号，防止触发业务逻辑误判
	if _syncing_form or _active_asset_id == &"":
		return
	asset_id_edited.emit(_active_asset_id, text)

func _on_path_changed(text: String) -> void:
	if _syncing_form or _active_asset_id == &"":
		return
	asset_path_edited.emit(_active_asset_id, text)

func _on_path_dropped(path: String) -> void:
	if _active_asset_id == &"":
		return
	asset_path_picked.emit(_active_asset_id, path)

func _on_path_dialog_file_selected(path: String) -> void:
	if _active_asset_id == &"":
		return
	asset_path_picked.emit(_active_asset_id, path)

func _on_group_option_selected(index: int) -> void:
	if _syncing_form or _active_asset_id == &"":
		return
	var group_name := String(_group_option.get_item_metadata(index))
	asset_group_edited.emit(_active_asset_id, group_name)

func _on_group_name_submitted(_new_text: String) -> void:
	_submit_group_rename()

func _on_group_name_focus_exited() -> void:
	_submit_group_rename()

func _submit_group_rename() -> void:
	if _active_group == AssetGroupConstants.NO_GROUP_SELECTED or _syncing_form:
		return
	group_rename_submitted.emit(_active_group, _group_name_edit.text)
#endregion

#region Helpers
## 返回空状态面板中滚动的快捷键提示文案。
func _default_hints() -> PackedStringArray:
	return PackedStringArray([
		"Folder tree shows real directory names; Group values stay uppercase (TEXTURES_ENTITIES)",
		"Right-click a folder to add a child group, rename, or delete",
		"Toolbar folder button creates a child group under the selected folder",
		"Ctrl+click or Shift+click to select multiple assets, then drag to a group",
		"Press + on the toolbar to add an id to the selected group",
		"Drag supported files from FileSystem onto the path field",
		"Drag assets between group folders to reorganize",
	])
#endregion
