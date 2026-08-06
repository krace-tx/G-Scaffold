@tool
extends HSplitContainer

## Assets 页总调度器:组装树控制器与详情展示器,通过 [AssetGroupManifestOps] 写 Manifest。

#region Signals
signal changed
signal status_message(text: String)
#endregion

#region Exports & State
@onready var _tree: AssetGroupTree = %GroupTree
@onready var _add_id_button: Button = %AddIdButton
@onready var _add_group_button: Button = %AddGroupButton
@onready var _empty_state: Control = %EmptyState
@onready var _detail_panel: PanelContainer = %DetailPanel
@onready var _group_detail: VBoxContainer = %GroupDetail
@onready var _group_name_edit: LineEdit = %GroupNameEdit
@onready var _multi_detail: VBoxContainer = %MultiDetail
@onready var _multi_count_label: Label = %MultiCountLabel
@onready var _multi_remove_button: Button = %MultiRemoveButton
@onready var _detail: VBoxContainer = %Detail
@onready var _id_edit: LineEdit = %IdEdit
@onready var _path_edit: EntryPathLineEdit = %PathEdit
@onready var _browse_button: Button = %BrowseButton
@onready var _group_option: OptionButton = %GroupOption
@onready var _drag_hint_panel: PanelContainer = %DragHintPanel
@onready var _remove_button: Button = %RemoveButton
@onready var _group_remove_button: Button = %GroupRemoveButton

var _manifest: EditAssetManifest
var _tree_controller := AssetGroupTreeController.new()
var _detail_presenter := AssetGroupDetailPresenter.new()
var _new_group_dialog: AcceptDialog
var _new_group_edit: LineEdit
var _rename_group_dialog: AcceptDialog
var _rename_group_edit: LineEdit
var _context_menu_target := ""
#endregion

#region Public API
func set_manifest(manifest: EditAssetManifest) -> void:
	_manifest = manifest
	if not is_node_ready():
		return
	_tree_controller.set_manifest(manifest)
	_detail_presenter.set_manifest(manifest)
	refresh()


func reload_manifest(manifest: EditAssetManifest) -> void:
	_manifest = manifest
	if not is_node_ready():
		return
	_tree_controller.set_manifest(manifest)
	_tree_controller.reset_selection()
	_detail_presenter.set_manifest(manifest)
	refresh()


func refresh() -> void:
	_tree_controller.rebuild()
	_detail_presenter.render(_tree_controller.selection())
#endregion

#region Lifecycle
func _ready() -> void:
	AssetGroupsEditorTheme.apply_asset_toolbar(self, _add_id_button, _add_group_button)
	_setup_dialogs()
	_bind_controllers()
	_detail_presenter.show_empty()


func _deferred_sync_tree_selection() -> void:
	_tree_controller.sync_selection_deferred()
#endregion

#region Internal
func _setup_dialogs() -> void:
	_new_group_edit = LineEdit.new()
	AssetGroupsEditorTheme.configure_dynamic_group_name_edit(_new_group_edit)
	_new_group_dialog = AcceptDialog.new()
	_new_group_dialog.title = "New asset group"
	_new_group_dialog.add_child(_new_group_edit)
	_new_group_dialog.confirmed.connect(_on_new_group_confirmed)
	add_child(_new_group_dialog)

	_rename_group_edit = LineEdit.new()
	AssetGroupsEditorTheme.configure_dynamic_group_name_edit(_rename_group_edit)
	_rename_group_dialog = AcceptDialog.new()
	_rename_group_dialog.title = "Rename group"
	_rename_group_dialog.add_child(_rename_group_edit)
	_rename_group_dialog.confirmed.connect(_on_rename_dialog_confirmed)
	add_child(_rename_group_dialog)


func _bind_controllers() -> void:
	_tree_controller.bind(self, _tree, _add_id_button, _add_group_button)
	_detail_presenter.bind(
		self,
		_empty_state,
		_detail_panel,
		_group_detail,
		_group_name_edit,
		_multi_detail,
		_multi_count_label,
		_multi_remove_button,
		_detail,
		_id_edit,
		_path_edit,
		_browse_button,
		_group_option,
		_drag_hint_panel,
		_remove_button,
		_group_remove_button
	)
	_connect_controller_signals()


func _connect_controller_signals() -> void:
	_tree_controller.selection_changed.connect(_on_selection_changed)
	_tree_controller.items_reassigned.connect(_on_items_reassigned)
	_tree_controller.group_context_action.connect(_on_group_context_action)
	_tree_controller.add_id_requested.connect(_on_add_id_requested)
	_tree_controller.add_group_requested.connect(_on_add_group_requested)

	_detail_presenter.asset_id_edited.connect(_on_asset_id_edited)
	_detail_presenter.asset_path_edited.connect(_on_asset_path_edited)
	_detail_presenter.asset_group_edited.connect(_on_asset_group_edited)
	_detail_presenter.asset_path_picked.connect(_on_asset_path_picked)
	_detail_presenter.group_rename_submitted.connect(_on_group_rename_submitted)
	_detail_presenter.remove_requested.connect(_on_remove_requested)
	_detail_presenter.group_remove_requested.connect(_on_group_remove_requested)


func _on_selection_changed(snapshot: AssetGroupSelection) -> void:
	_detail_presenter.render(snapshot)


func _on_group_remove_requested(group_name: StringName) -> void:
	var result := AssetGroupManifestOps.remove_group(_manifest, group_name)
	_apply_result(result)
	if result.is_ok():
		_commit_change()


func _on_items_reassigned(asset_ids: Array[StringName], target_group: StringName) -> void:
	var result := AssetGroupManifestOps.reassign_assets(_manifest, asset_ids, target_group)
	_apply_result(result)
	if result.is_ok():
		var snapshot := _tree_controller.selection()
		snapshot.asset_ids = asset_ids.duplicate()
		snapshot.asset_id = &"" if asset_ids.size() != 1 else asset_ids[0]
	_commit_change()


func _on_group_context_action(group_name: String, action_id: int) -> void:
	match action_id:
		0:
			_context_menu_target = group_name
			_rename_group_edit.text = group_name
			_rename_group_dialog.popup_centered()
		1:
			var result := AssetGroupManifestOps.remove_group(_manifest, StringName(group_name))
			_apply_result(result)
			if result.is_ok():
				_commit_change()


func _on_add_id_requested(group_context: String) -> void:
	var result := AssetGroupManifestOps.add_asset(_manifest, group_context)
	_apply_result(result)
	if result.is_err():
		return
	var entry: EditAssetEntry = result.value
	_tree_controller.selection().asset_id = entry.id
	_commit_change()


func _on_add_group_requested(prefill: String = "") -> void:
	_new_group_edit.text = prefill
	_new_group_dialog.popup_centered()


func _on_new_group_confirmed() -> void:
	var result := AssetGroupManifestOps.add_group(_manifest, _new_group_edit.text)
	_apply_result(result)
	if result.is_ok():
		_commit_change()


func _on_rename_dialog_confirmed() -> void:
	_apply_group_rename(StringName(_context_menu_target), _rename_group_edit.text)


func _on_group_rename_submitted(group_name: StringName, new_text: String) -> void:
	_apply_group_rename(group_name, new_text)


func _apply_group_rename(old_name: StringName, raw_new_name: String) -> void:
	var result := AssetGroupManifestOps.rename_group(_manifest, old_name, raw_new_name)
	_apply_result(result)
	if result.is_err():
		_detail_presenter.show_group(old_name)
		return
	_tree_controller.selection().group_name = result.value
	_commit_change()


func _on_asset_id_edited(asset_id: StringName, new_text: String) -> void:
	var result := AssetGroupManifestOps.update_asset_id(_manifest, asset_id, new_text)
	_apply_result(result)
	if result.is_err():
		_detail_presenter.show_asset(asset_id)
		return
	var new_id: StringName = result.value
	_tree_controller.sync_asset_tree_item(new_id)
	_detail_presenter.show_asset(new_id)
	changed.emit()


func _on_asset_path_edited(asset_id: StringName, path: String) -> void:
	var result := AssetGroupManifestOps.update_asset_path(_manifest, asset_id, path)
	_apply_result(result)
	if result.is_ok():
		changed.emit()


func _on_asset_group_edited(asset_id: StringName, group_name: String) -> void:
	var result := AssetGroupManifestOps.set_asset_group(_manifest, asset_id, group_name)
	_apply_result(result)
	if result.is_ok():
		_commit_change()


func _on_asset_path_picked(asset_id: StringName, path: String) -> void:
	var result := AssetGroupManifestOps.apply_path_pick(_manifest, asset_id, path)
	_apply_result(result)
	if result.is_err():
		return
	var entry: EditAssetEntry = result.value
	_tree_controller.sync_asset_tree_item(entry.id)
	_detail_presenter.show_asset(entry.id)
	changed.emit()


func _on_remove_requested() -> void:
	var snapshot := _tree_controller.selection()
	var ids := snapshot.asset_ids.duplicate()
	if ids.is_empty() and snapshot.asset_id != &"":
		ids = [snapshot.asset_id]
	var result := AssetGroupManifestOps.remove_assets(_manifest, ids)
	_apply_result(result)
	if result.is_ok():
		_commit_change()


func _commit_change() -> void:
	refresh()
	changed.emit()
#endregion

#region Helpers
func _apply_result(result: RefCounted) -> void:
	if result.is_err():
		status_message.emit(String(result.error))
#endregion
