@tool
class_name AssetGroupSelection
extends RefCounted

## 树选中态快照:由 [AssetGroupTreeController] 产出,[AssetGroupDetailPresenter] 消费。

enum Mode { EMPTY, SINGLE_ASSET, MULTI_ASSET, GROUP }

var mode: Mode = Mode.EMPTY
var asset_id: StringName = &""
var asset_ids: Array[StringName] = []
var group_name: StringName = AssetGroupConstants.NO_GROUP_SELECTED


static func empty() -> AssetGroupSelection:
	return AssetGroupSelection.new()


static func single_asset(asset_id: StringName) -> AssetGroupSelection:
	var snapshot := AssetGroupSelection.new()
	snapshot.mode = Mode.SINGLE_ASSET
	snapshot.asset_id = asset_id
	snapshot.asset_ids = [asset_id]
	return snapshot


static func multi_assets(asset_ids: Array[StringName]) -> AssetGroupSelection:
	var snapshot := AssetGroupSelection.new()
	snapshot.mode = Mode.MULTI_ASSET
	snapshot.asset_ids = asset_ids.duplicate()
	return snapshot


static func group(group_name: StringName) -> AssetGroupSelection:
	var snapshot := AssetGroupSelection.new()
	snapshot.mode = Mode.GROUP
	snapshot.group_name = group_name
	return snapshot
