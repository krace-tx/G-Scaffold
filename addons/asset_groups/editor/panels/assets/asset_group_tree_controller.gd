@tool
class_name AssetGroupTreeController
extends RefCounted

## 左侧分组树:构建、选中态、拖拽意图与分组上下文菜单,不直接写 [EditAssetManifest]。

#region Signals
signal selection_changed(snapshot: AssetGroupSelection)
signal items_reassigned(asset_ids: Array[StringName], target_group: StringName)
signal group_context_action(group_name: String, action_id: int)
signal add_id_requested(group_context: String)
signal add_group_requested(prefill: String)
#endregion

#region Exports & State
var _host: Control
var _tree: AssetGroupTree
var _add_id_button: Button
var _add_group_button: Button
var _context_menu: PopupMenu
var _context_menu_target := ""

var _manifest: EditAssetManifest
var _selection := AssetGroupSelection.empty()
var _selected_tree_item: TreeItem
#endregion

#region Public API
func bind(
	host: Control,
	tree: AssetGroupTree,
	add_id_button: Button,
	add_group_button: Button
) -> void:
	_host = host
	_tree = tree
	_add_id_button = add_id_button
	_add_group_button = add_group_button
	_setup_tree_style()
	_setup_context_menu()
	_connect_signals()


func set_manifest(manifest: EditAssetManifest) -> void:
	_manifest = manifest


func rebuild() -> void:
	if _manifest == null or _tree == null:
		return

	var keep_id := _selection.asset_id
	var keep_ids := _selection.asset_ids.duplicate()
	var keep_group := _selection.group_name

	_tree.clear()
	var root := _tree.create_item()
	_tree.hide_root = true

	var group_row_color := _host.get_theme_color("dark_color_1", "Editor")
	var found_assets: Array[TreeItem] = []
	var found_state := {
		"asset": null,
		"assets": found_assets,
		"group": null,
	}

	var hierarchy := AssetGroupTreeBuilder.build(_manifest)
	_build_folder_items(root, hierarchy, group_row_color, keep_id, keep_ids, keep_group, found_state)

	var ungrouped := _manifest.assets_in_group(&"")
	if not ungrouped.is_empty():
		var u_item := _tree.create_item(root)
		u_item.set_text(0, AssetGroupConstants.UNGROUPED_LABEL)
		u_item.set_custom_bg_color(0, group_row_color)
		u_item.set_metadata(0, _group_tree_meta(&""))
		if keep_id == &"" and keep_group == &"":
			found_state["group"] = u_item
		for entry in ungrouped:
			var a_item := _tree.create_item(u_item)
			a_item.set_text(0, String(entry.id) if entry.id != &"" else "(unnamed)")
			a_item.set_metadata(0, entry.id)
			if entry.id == keep_id and keep_id != &"":
				found_state["asset"] = a_item
			if keep_ids.has(entry.id):
				found_state["assets"].append(a_item)

	_restore_tree_selection(
		found_state["asset"],
		found_assets,
		found_state["group"],
		keep_id,
		keep_ids,
		keep_group
	)


func selection() -> AssetGroupSelection:
	return _selection


func reset_selection() -> void:
	_selection = AssetGroupSelection.empty()
	_selected_tree_item = null
	if _tree != null:
		_tree.deselect_all()


func sync_asset_tree_item(asset_id: StringName) -> void:
	var item := find_tree_item_for_asset(asset_id)
	if item == null:
		return
	item.set_text(0, String(asset_id) if asset_id != &"" else "(unnamed)")
	item.set_metadata(0, asset_id)
	_selected_tree_item = item


func find_tree_item_for_asset(asset_id: StringName) -> TreeItem:
	return _find_tree_item(func(meta: Variant) -> bool:
		return meta == asset_id
	)


func current_group_context() -> String:
	var group_name := _resolve_focused_group_name()
	if group_name != AssetGroupConstants.NO_GROUP_SELECTED:
		return String(group_name)
	var item := _tree.get_selected()
	if item == null:
		return ""
	var parent := item.get_parent()
	if parent == null:
		return ""
	return String(_group_name_from_meta(parent.get_metadata(0)))
#endregion

#region Lifecycle
func _setup_tree_style() -> void:
	AssetGroupsEditorTheme.apply_tree(_host, _tree)
	_tree.select_mode = Tree.SELECT_MULTI


func _setup_context_menu() -> void:
	_context_menu = PopupMenu.new()
	_context_menu.id_pressed.connect(_on_context_menu_id_pressed)
	_host.add_child(_context_menu)


func _connect_signals() -> void:
	_tree.multi_selected.connect(_on_tree_multi_selected)
	_tree.nothing_selected.connect(_on_tree_nothing_selected)
	_tree.item_mouse_selected.connect(_on_tree_mouse_selected)
	_tree.reassign_requested.connect(_on_reassign_requested)
	_add_id_button.pressed.connect(_on_add_id_pressed)
	_add_group_button.pressed.connect(_on_add_group_pressed)
#endregion

#region Tree build
func _build_folder_items(
	parent_item: TreeItem,
	folder: AssetGroupTreeBuilder.FolderNode,
	group_row_color: Color,
	keep_id: StringName,
	keep_ids: Array[StringName],
	keep_group: StringName,
	found_state: Dictionary
) -> void:
	for segment in AssetGroupTreeBuilder.sorted_child_segments(folder):
		var child: AssetGroupTreeBuilder.FolderNode = folder.children[segment]
		var g_item := _tree.create_item(parent_item)
		var label := child.display_segment if not child.display_segment.is_empty() else child.segment
		if AssetGroupTreeBuilder.folder_is_empty(child):
			label = "%s (empty)" % label
		g_item.set_text(0, label)
		g_item.set_custom_bg_color(0, group_row_color)
		g_item.set_metadata(0, _group_tree_meta(StringName(child.full_name)))
		if keep_id == &"" and keep_group == StringName(child.full_name):
			found_state["group"] = g_item

		for entry in _sorted_assets(child.assets):
			var a_item := _tree.create_item(g_item)
			a_item.set_text(0, String(entry.id) if entry.id != &"" else "(unnamed)")
			a_item.set_metadata(0, entry.id)
			if entry.id == keep_id and keep_id != &"":
				found_state["asset"] = a_item
			if keep_ids.has(entry.id):
				found_state["assets"].append(a_item)

		_build_folder_items(
			g_item,
			child,
			group_row_color,
			keep_id,
			keep_ids,
			keep_group,
			found_state
		)


static func _sorted_assets(entries: Array[EditAssetEntry]) -> Array[EditAssetEntry]:
	var sorted := entries.duplicate()
	sorted.sort_custom(func(a: EditAssetEntry, b: EditAssetEntry) -> bool:
		return String(a.id) < String(b.id)
	)
	return sorted
#endregion

#region Internal
func _restore_tree_selection(
	found_item: TreeItem,
	found_items: Array[TreeItem],
	found_group_item: TreeItem,
	keep_id: StringName,
	keep_ids: Array[StringName],
	keep_group: StringName
) -> void:
	if found_items.size() > 1:
		_tree.deselect_all()
		for item in found_items:
			item.select(0)
		_selected_tree_item = found_items[-1]
		_set_selection(AssetGroupSelection.multi_assets(keep_ids))
	elif found_item != null:
		found_item.select(0)
		_selected_tree_item = found_item
		_set_selection(AssetGroupSelection.single_asset(keep_id))
	elif found_group_item != null:
		found_group_item.select(0)
		_selected_tree_item = found_group_item
		_set_selection(AssetGroupSelection.group(keep_group))
	else:
		_selected_tree_item = null
		_set_selection(AssetGroupSelection.empty())


func _set_selection(snapshot: AssetGroupSelection) -> void:
	_selection = snapshot
	selection_changed.emit(snapshot)


func _sync_tree_selection() -> void:
	var asset_ids := _collect_selected_asset_ids()
	if asset_ids.size() > 1:
		_selected_tree_item = _tree.get_selected()
		_set_selection(AssetGroupSelection.multi_assets(asset_ids))
		return
	if asset_ids.size() == 1:
		_selected_tree_item = find_tree_item_for_asset(asset_ids[0])
		_set_selection(AssetGroupSelection.single_asset(asset_ids[0]))
		return

	var focused_asset_id := _resolve_focused_asset_id()
	if focused_asset_id != &"":
		_selected_tree_item = _tree.get_selected()
		_set_selection(AssetGroupSelection.single_asset(focused_asset_id))
		return

	var group_name := _resolve_focused_group_name()
	if group_name != AssetGroupConstants.NO_GROUP_SELECTED:
		_selected_tree_item = _find_tree_item_for_group(group_name)
		_set_selection(AssetGroupSelection.group(group_name))
		return

	_on_tree_nothing_selected()


func _on_tree_multi_selected(_item: TreeItem, _column: int, _selected: bool) -> void:
	_sync_tree_selection()


func _on_tree_nothing_selected() -> void:
	_selected_tree_item = null
	_set_selection(AssetGroupSelection.empty())


func _on_tree_mouse_selected(position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_LEFT:
		_host.call_deferred("_deferred_sync_tree_selection")
		return
	if mouse_button_index != MOUSE_BUTTON_RIGHT:
		return
	var item := _tree.get_item_at_position(position)
	if item == null or not _is_group_tree_meta(item.get_metadata(0)):
		return
	var group_name := _group_name_from_meta(item.get_metadata(0))
	if group_name == &"":
		return
	_context_menu_target = String(group_name)
	_context_menu.clear()
	_context_menu.add_item("Add child group", 2)
	if AssetGroupTreeBuilder.is_manageable_group(_manifest, group_name):
		_context_menu.add_item("Rename group", 0)
		_context_menu.add_item("Delete group", 1)
	_context_menu.position = DisplayServer.mouse_get_position()
	_context_menu.popup()


func sync_selection_deferred() -> void:
	_sync_tree_selection()


func _on_context_menu_id_pressed(id: int) -> void:
	match id:
		2:
			add_group_requested.emit("%s_" % _context_menu_target)
		_:
			group_context_action.emit(_context_menu_target, id)


func _on_add_group_pressed() -> void:
	var parent_path := current_group_context()
	if parent_path.is_empty():
		add_group_requested.emit("")
	else:
		add_group_requested.emit("%s_" % parent_path)


func _on_add_id_pressed() -> void:
	add_id_requested.emit(current_group_context())


func _on_reassign_requested(asset_ids: Array[StringName], group_name: StringName) -> void:
	var target_group := group_name
	if String(group_name) == AssetGroupConstants.UNGROUPED_LABEL:
		target_group = &""
	items_reassigned.emit(asset_ids, target_group)
#endregion

#region Helpers
func _group_tree_meta(group_name: StringName) -> Dictionary:
	return {"kind": AssetGroupConstants.GROUP_META_KIND, "name": String(group_name)}


func _group_name_from_meta(meta: Variant) -> StringName:
	if not _is_group_tree_meta(meta):
		return &""
	return StringName(meta["name"])


func _is_group_tree_meta(meta: Variant) -> bool:
	return typeof(meta) == TYPE_DICTIONARY and meta.get("kind", &"") == AssetGroupConstants.GROUP_META_KIND


func _group_label_from_item(item: TreeItem) -> String:
	if item == null:
		return ""
	var group_name := _group_name_from_meta(item.get_metadata(0))
	if group_name == &"":
		return AssetGroupConstants.UNGROUPED_LABEL
	return String(group_name)


func _resolve_focused_group_name() -> StringName:
	var item := _tree.get_selected()
	if item == null:
		return AssetGroupConstants.NO_GROUP_SELECTED
	var meta: Variant = item.get_metadata(0)
	if _is_group_tree_meta(meta):
		return _group_name_from_meta(meta)
	return AssetGroupConstants.NO_GROUP_SELECTED


func _resolve_focused_asset_id() -> StringName:
	var item := _tree.get_selected()
	if item == null:
		return &""
	var meta: Variant = item.get_metadata(0)
	if meta != null and not _is_group_tree_meta(meta):
		return meta
	return &""


func _find_tree_item_for_group(group_name: StringName) -> TreeItem:
	return _find_tree_item(func(meta: Variant) -> bool:
		return _is_group_tree_meta(meta) and StringName(meta["name"]) == group_name
	)


func _find_tree_item(match_meta: Callable) -> TreeItem:
	var root := _tree.get_root()
	if root == null:
		return null
	return _find_tree_item_recursive(root, match_meta)


func _find_tree_item_recursive(item: TreeItem, match_meta: Callable) -> TreeItem:
	var meta: Variant = item.get_metadata(0)
	if meta != null and match_meta.call(meta):
		return item
	var child := item.get_first_child()
	while child != null:
		var found := _find_tree_item_recursive(child, match_meta)
		if found != null:
			return found
		child = child.get_next()
	return null


func _collect_selected_asset_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	var item := _tree.get_next_selected(null)
	while item != null:
		var meta: Variant = item.get_metadata(0)
		if meta != null and not _is_group_tree_meta(meta):
			ids.append(meta)
		item = _tree.get_next_selected(item)
	return ids
#endregion
