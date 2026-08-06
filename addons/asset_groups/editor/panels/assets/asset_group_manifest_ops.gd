@tool
class_name AssetGroupManifestOps
extends RefCounted

## Assets 页对 [EditAssetManifest] 的可失败写操作,统一返回插件内 [_Result]。

const _Result := preload("res://addons/asset_groups/internal/asset_group_result.gd")

#region Public API
static func add_group(manifest: EditAssetManifest, raw_name: String) -> RefCounted:
	var group_name := raw_name.strip_edges()
	if group_name.is_empty():
		return _Result.err("组名不能为空")
	if not AssetGroupsGeneratorUtils.is_valid_identifier(StringName(group_name)):
		return _Result.err("组名 '%s' 不是合法标识符" % group_name)
	manifest.add_asset_group(StringName(group_name))
	return _Result.ok(StringName(group_name))


static func rename_group(
	manifest: EditAssetManifest, old_name: StringName, raw_new_name: String
) -> RefCounted:
	if old_name == &"":
		return _Result.err("该分组不可重命名")
	var new_name := raw_new_name.strip_edges()
	if new_name.is_empty():
		return _Result.err("组名不能为空")
	if new_name == String(old_name):
		return _Result.ok(old_name)
	if not AssetGroupsGeneratorUtils.is_valid_identifier(StringName(new_name)):
		return _Result.err("组名 '%s' 不是合法标识符" % new_name)
	manifest.rename_asset_group(old_name, StringName(new_name))
	return _Result.ok(StringName(new_name))


static func remove_group(manifest: EditAssetManifest, group_name: StringName) -> RefCounted:
	if group_name == &"":
		return _Result.err("该分组不可删除")
	manifest.remove_asset_group(group_name)
	return _Result.ok(null)


static func add_asset(manifest: EditAssetManifest, group_name: String) -> RefCounted:
	var entry := EditAssetEntry.new()
	entry.id = _unique_asset_id(manifest, AssetGroupConstants.DEFAULT_NEW_ASSET_ID_BASE)
	entry.group = StringName(group_name)
	manifest.assets.append(entry)
	return _Result.ok(entry)


static func remove_assets(manifest: EditAssetManifest, asset_ids: Array[StringName]) -> RefCounted:
	if asset_ids.is_empty():
		return _Result.err("未选中任何资产")
	for asset_id in asset_ids:
		var entry := manifest.find_asset(asset_id)
		if entry != null:
			manifest.assets.erase(entry)
	return _Result.ok(null)


static func reassign_assets(
	manifest: EditAssetManifest, asset_ids: Array[StringName], target_group: StringName
) -> RefCounted:
	if asset_ids.is_empty():
		return _Result.err("未选中任何资产")
	for asset_id in asset_ids:
		var entry := manifest.find_asset(asset_id)
		if entry == null:
			continue
		entry.group = target_group
	return _Result.ok(null)


static func update_asset_id(
	manifest: EditAssetManifest, current_id: StringName, new_text: String
) -> RefCounted:
	var entry := manifest.find_asset(current_id)
	if entry == null:
		return _Result.err("资产 '%s' 不存在" % current_id)
	var new_id := StringName(new_text)
	if new_id != &"" and not AssetGroupsGeneratorUtils.is_valid_identifier(new_id):
		return _Result.err("id '%s' 不是合法标识符" % new_text)
	entry.id = new_id
	return _Result.ok(new_id)


static func update_asset_path(
	manifest: EditAssetManifest, asset_id: StringName, path: String
) -> RefCounted:
	var entry := manifest.find_asset(asset_id)
	if entry == null:
		return _Result.err("资产 '%s' 不存在" % asset_id)
	entry.path = path
	return _Result.ok(path)


static func apply_path_pick(
	manifest: EditAssetManifest, asset_id: StringName, path: String
) -> RefCounted:
	var entry := manifest.find_asset(asset_id)
	if entry == null:
		return _Result.err("资产 '%s' 不存在" % asset_id)
	entry.path = path
	var new_id := EntryPathUtils.resolve_id_after_path_pick(path, entry.id, func(id: StringName) -> bool:
		var other := manifest.find_asset(id)
		return other != null and other != entry
	)
	if new_id != entry.id:
		entry.id = new_id
	return _Result.ok(entry)


static func set_asset_group(
	manifest: EditAssetManifest, asset_id: StringName, group_name: String
) -> RefCounted:
	var entry := manifest.find_asset(asset_id)
	if entry == null:
		return _Result.err("资产 '%s' 不存在" % asset_id)
	entry.group = StringName(group_name)
	return _Result.ok(entry.group)
#endregion

#region Internal
static func _unique_asset_id(manifest: EditAssetManifest, base: String) -> StringName:
	var n := 1
	var candidate := base
	while manifest.find_asset(StringName(candidate)) != null:
		n += 1
		candidate = "%s_%d" % [base, n]
	return StringName(candidate)
#endregion
