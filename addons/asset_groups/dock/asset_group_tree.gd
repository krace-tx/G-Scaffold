@tool
class_name AssetGroupTree
extends Tree

## 资产分组树的"哑组件":只认自己面前的 [TreeItem] 长什么样,不碰 [AssetManifest]。
## 分组节点(顶层)不设 metadata,资产节点(叶子)的 metadata 是它的 id——上层
## [AssetGroupPanel] 靠这个区分两种节点,这里只管拖拽手势本身。
##
## 拖资产行到另一个分组行 = 发一个 [signal reassign_requested] 意图信号,真正
## 改 manifest.assets[].group 的逻辑在上层面板,这里不持有业务状态。

signal reassign_requested(asset_id: StringName, group_name: StringName)


func _get_drag_data(at_position: Vector2) -> Variant:
	var item := get_item_at_position(at_position)
	if item == null or item.get_metadata(0) == null:
		return null

	var preview := Label.new()
	preview.text = item.get_text(0)
	set_drag_preview(preview)
	return {"asset_id": item.get_metadata(0)}


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has("asset_id"):
		return false
	var item := get_item_at_position(at_position)
	return item != null and item.get_metadata(0) == null


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var item := get_item_at_position(at_position)
	if item == null:
		return
	var group_name := item.get_text(0).trim_suffix(" (empty)")
	reassign_requested.emit(data["asset_id"], StringName(group_name))
