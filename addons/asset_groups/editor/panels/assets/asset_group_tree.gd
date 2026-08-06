@tool
class_name AssetGroupTree
extends Tree

## 资产分组树的"哑组件":只认自己面前的 [TreeItem] 长什么样,不碰 [EditAssetManifest]。
## 分组节点 metadata = { kind: &"group", name: ... },资产节点 metadata = 资产 id。
## 拖资产行到分组行 = 发 [signal reassign_requested];多选时带上全部选中资产。

signal reassign_requested(asset_ids: Array[StringName], group_name: StringName)

const _DRAG_THRESHOLD := 8.0
const _UNGROUPED_LABEL := "— ungrouped —"

var _drag_press_pos := Vector2(-1.0, -1.0)


func _get_drag_data(at_position: Vector2) -> Variant:
	return _build_drag_data(get_item_at_position(at_position))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return
		_drag_press_pos = mouse_button.position if mouse_button.pressed else Vector2(-1.0, -1.0)
		return

	if event is InputEventMouseMotion:
		_try_force_drag(event as InputEventMouseMotion)


func _try_force_drag(motion: InputEventMouseMotion) -> void:
	if _drag_press_pos.x < 0.0:
		return
	if not (motion.button_mask & MOUSE_BUTTON_MASK_LEFT):
		return
	if _drag_press_pos.distance_to(motion.position) < _DRAG_THRESHOLD:
		return
	if get_viewport().gui_is_dragging():
		return

	var item := get_item_at_position(_drag_press_pos)
	var data := _build_drag_data(item)
	_drag_press_pos = Vector2(-1.0, -1.0)
	if data == null:
		return
	force_drag(data, _make_drag_preview(item, data))


func _build_drag_data(item: TreeItem) -> Variant:
	if item == null:
		return null
	var asset_ids := _collect_drag_asset_ids(item)
	if asset_ids.is_empty():
		return null
	return {"asset_ids": asset_ids}


func _make_drag_preview(item: TreeItem, data: Dictionary) -> Control:
	var preview := Label.new()
	var asset_ids: Array = data["asset_ids"]
	if asset_ids.size() > 1:
		preview.text = "%d assets" % asset_ids.size()
	else:
		preview.text = item.get_text(0)
	return preview


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has("asset_ids"):
		return false
	var item := get_item_at_position(at_position)
	if item == null or not _is_group_meta(item.get_metadata(0)):
		return false
	drop_mode_flags = DROP_MODE_ON_ITEM
	return true


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var item := get_item_at_position(at_position)
	if item == null:
		return
	reassign_requested.emit(data["asset_ids"], _group_name_from_item(item))


func _collect_drag_asset_ids(anchor_item: TreeItem) -> Array[StringName]:
	var anchor_meta: Variant = anchor_item.get_metadata(0)
	if anchor_meta == null or _is_group_meta(anchor_meta):
		return []

	var selected: Array[StringName] = []
	var item := get_next_selected(null)
	while item != null:
		var meta: Variant = item.get_metadata(0)
		if meta != null and not _is_group_meta(meta):
			selected.append(meta)
		item = get_next_selected(item)

	if anchor_meta in selected:
		return selected
	return [anchor_meta]


func _is_group_meta(meta: Variant) -> bool:
	return typeof(meta) == TYPE_DICTIONARY and meta.get("kind", &"") == &"group"


func _group_name_from_item(item: TreeItem) -> StringName:
	var meta: Variant = item.get_metadata(0)
	if typeof(meta) == TYPE_DICTIONARY and meta.get("kind", &"") == &"group":
		return StringName(meta["name"])
	return &""
