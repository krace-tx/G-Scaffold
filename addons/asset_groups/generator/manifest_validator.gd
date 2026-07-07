@tool
class_name ManifestValidator
extends RefCounted

## Generate 前的两级校验:硬错误(非空即阻断 Generate)与软警告(仅提示,不阻断)。
## 仅校验 id+路径齐全的条目;空 manifest 与未填完的草稿行均允许 Generate。

#region Public API
## 硬错误:可生成条目内 id 非法/重复。
static func hard_errors(manifest: AssetManifest) -> PackedStringArray:
	var errors := PackedStringArray()
	errors.append_array(_check_ids("Scenes", ManifestEntries.complete_scenes(manifest)))
	errors.append_array(_check_ids("UI", ManifestEntries.complete_uis(manifest)))
	errors.append_array(_check_ids("Assets", ManifestEntries.complete_assets(manifest)))
	return errors


## 软警告:草稿跳过 / 分组引用问题。
static func soft_warnings(manifest: AssetManifest) -> PackedStringArray:
	var warnings := ManifestEntries.incomplete_warnings(manifest)

	var asset_groups: Dictionary = {}
	for entry in ManifestEntries.complete_assets(manifest):
		if entry.group != &"":
			asset_groups[entry.group] = true

	var scene_groups: Dictionary = {}
	for entry in ManifestEntries.complete_scenes(manifest):
		if entry.asset_group != &"":
			scene_groups[entry.asset_group] = true
			if not asset_groups.has(entry.asset_group):
				warnings.append("场景 '%s' 引用的分组 '%s' 下没有任何资产" % [entry.id, entry.asset_group])

	for group in asset_groups:
		if group != &"core" and not scene_groups.has(group):
			warnings.append("分组 '%s' 没有被任何场景引用,资产不会被预载" % group)

	return warnings
#endregion

#region Helpers
static func _check_ids(label: String, entries: Array) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_ids: Dictionary = {}
	var seen_const_names: Dictionary = {}
	for entry in entries:
		var id: StringName = entry.id
		var text := String(id)
		if not GeneratorUtils.is_valid_identifier(id):
			errors.append("%s: id '%s' 不是合法标识符" % [label, text])
			continue
		if seen_ids.has(id):
			errors.append("%s: id '%s' 重复" % [label, text])
			continue
		var cname := GeneratorUtils.const_name(id)
		if seen_const_names.has(cname):
			errors.append(
				"%s: id '%s' 转成常量名后与 '%s' 冲突(%s)" % [label, text, seen_const_names[cname], cname]
			)
			continue
		seen_ids[id] = true
		seen_const_names[cname] = text
	return errors
#endregion
