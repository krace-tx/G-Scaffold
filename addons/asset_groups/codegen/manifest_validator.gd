@tool
class_name ManifestValidator
extends RefCounted

## Generate 前的两级校验:硬错误(非空即阻断 Generate)与软警告(仅提示,不阻断)。
## 仅校验 id+路径齐全的条目;空 manifest 与未填完的草稿行均允许 Generate。

#region Public API
## 硬错误:可生成条目内 id 非法/重复。
static func hard_errors(manifest: EditAssetManifest) -> PackedStringArray:
	var errors := PackedStringArray()
	errors.append_array(_check_ids("Scenes", ManifestEntries.complete_scenes(manifest)))
	errors.append_array(_check_ids("UI", ManifestEntries.complete_uis(manifest)))
	errors.append_array(_check_asset_paths(ManifestEntries.complete_assets(manifest)))
	errors.append_array(_check_ids("Resources", ManifestEntries.complete_resources(manifest)))
	errors.append_array(_check_resource_paths(ManifestEntries.complete_resources(manifest)))
	return errors


## 软警告:草稿跳过。
static func soft_warnings(manifest: EditAssetManifest) -> PackedStringArray:
	return ManifestEntries.incomplete_warnings(manifest)
#endregion

#region Helpers
static func _check_ids(label: String, entries: Array) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_ids: Dictionary = {}
	var seen_const_names: Dictionary = {}
	for entry in entries:
		var id: StringName = entry.id
		var text := String(id)
		if not AssetGroupsGeneratorUtils.is_valid_identifier(id):
			errors.append("%s: id '%s' 不是合法标识符" % [label, text])
			continue
		if seen_ids.has(id):
			errors.append("%s: id '%s' 重复" % [label, text])
			continue
		var cname := AssetGroupsGeneratorUtils.const_name(id)
		if seen_const_names.has(cname):
			errors.append(
				"%s: id '%s' 转成常量名后与 '%s' 冲突(%s)" % [label, text, seen_const_names[cname], cname]
			)
			continue
		seen_ids[id] = true
		seen_const_names[cname] = text
	return errors


static func _check_asset_paths(entries: Array) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_paths: Dictionary = {}
	for entry in entries:
		if seen_paths.has(entry.path):
			errors.append("Assets: path '%s' 重复" % entry.path)
			continue
		seen_paths[entry.path] = true
	return errors


static func _check_resource_paths(entries: Array) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_paths: Dictionary = {}
	for entry in entries:
		if seen_paths.has(entry.path):
			errors.append("Resources: path '%s' 重复" % entry.path)
			continue
		seen_paths[entry.path] = true
	return errors
#endregion
