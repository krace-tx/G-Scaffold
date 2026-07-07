@tool
class_name ManifestEntries
extends RefCounted

## 从 [AssetManifest] 筛出可生成条目,跳过 id/path 均为空的草稿行。

#region Public API
static func complete_scenes(manifest: AssetManifest) -> Array[SceneEntry]:
	var result: Array[SceneEntry] = []
	for entry in manifest.scenes:
		if entry.id != &"" and not entry.scene_path.is_empty():
			result.append(entry)
	return result


static func complete_uis(manifest: AssetManifest) -> Array[UIEntry]:
	var result: Array[UIEntry] = []
	for entry in manifest.uis:
		if entry.id != &"" and not entry.scene_path.is_empty():
			result.append(entry)
	return result


static func complete_assets(manifest: AssetManifest) -> Array[AssetEntry]:
	var result: Array[AssetEntry] = []
	for entry in manifest.assets:
		if entry.id != &"" and not entry.path.is_empty():
			result.append(entry)
	return result


## 有条目填了 id 或路径但未成对完成的,Generate 会跳过并在此提示。
static func incomplete_warnings(manifest: AssetManifest) -> PackedStringArray:
	var warnings := PackedStringArray()
	warnings.append_array(_incomplete_lines("Scenes", manifest.scenes.size(), complete_scenes(manifest).size()))
	warnings.append_array(_incomplete_lines("UI", manifest.uis.size(), complete_uis(manifest).size()))
	warnings.append_array(_incomplete_lines("Assets", manifest.assets.size(), complete_assets(manifest).size()))
	return warnings
#endregion

#region Helpers
static func _incomplete_lines(label: String, total: int, complete: int) -> PackedStringArray:
	var skipped := total - complete
	if skipped <= 0:
		return PackedStringArray()
	return PackedStringArray(["%s: 跳过 %d 条未填完整的草稿" % [label, skipped]])
#endregion
