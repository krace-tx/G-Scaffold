@tool
class_name ManifestCodegenFingerprints
extends RefCounted

## 为 Generate 管线计算 manifest 分段指纹,推导脏标记式增量写入开关。
##
## 指纹在成功 Generate 后由 Dock 缓存;Reload 会清空缓存并强制下次全量写入。

const SIG_SCENES := "scenes"
const SIG_UIS := "uis"
const SIG_ASSETS := "assets"
const SIG_RESOURCES := "resources"

#region Public API
static func compute(manifest: EditAssetManifest) -> Dictionary:
	return {
		SIG_SCENES: _scenes_signature(manifest),
		SIG_UIS: _uis_signature(manifest),
		SIG_ASSETS: _assets_signature(manifest),
		SIG_RESOURCES: _resources_signature(manifest),
	}


## [param previous] 为空时返回全量写入(首次 Generate 或 Reload 后)。
static func derive_flags(current: Dictionary, previous: Dictionary) -> GenerateFlags:
	var flags := GenerateFlags.new()
	if previous.is_empty():
		return flags

	flags.scene_registry = current[SIG_SCENES] != previous.get(SIG_SCENES, "")
	flags.scenes_accessor = flags.scene_registry
	flags.ui_registry = current[SIG_UIS] != previous.get(SIG_UIS, "")
	flags.uis_accessor = flags.ui_registry
	flags.asset_registry = current[SIG_ASSETS] != previous.get(SIG_ASSETS, "")
	flags.assets_accessor = flags.asset_registry
	flags.resource_registry = current[SIG_RESOURCES] != previous.get(SIG_RESOURCES, "")
	flags.resources_accessor = flags.resource_registry
	return flags
#endregion

#region Signatures
static func _scenes_signature(manifest: EditAssetManifest) -> String:
	var parts := PackedStringArray()
	for entry in ManifestEntries.complete_scenes(manifest):
		parts.append("%s|%s" % [entry.id, entry.scene_path])
	parts.sort()
	return "|".join(parts)


static func _uis_signature(manifest: EditAssetManifest) -> String:
	var parts := PackedStringArray()
	for entry in ManifestEntries.complete_uis(manifest):
		parts.append(
			"%s|%s|%d|%d" % [entry.id, entry.scene_path, int(entry.layer), int(entry.cache)]
		)
	parts.sort()
	return "|".join(parts)


static func _assets_signature(manifest: EditAssetManifest) -> String:
	var parts := PackedStringArray()
	for entry in ManifestEntries.complete_assets(manifest):
		parts.append("%s|%s|%s" % [entry.id, entry.path, entry.group])
	parts.sort()
	return "|".join(parts)


static func _resources_signature(manifest: EditAssetManifest) -> String:
	var parts := PackedStringArray()
	for entry in ManifestEntries.complete_resources(manifest):
		parts.append("%s|%s|%s" % [entry.id, entry.path, entry.group])
	parts.sort()
	return "|".join(parts)
#endregion
