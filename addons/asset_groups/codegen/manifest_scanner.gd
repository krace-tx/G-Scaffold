@tool
class_name ManifestScanner
extends RefCounted

## 扫描项目目录,把尚未登记的 .tscn / 媒体资源导入 [EditAssetManifest]。
## 只追加、不覆盖已有路径;id 取合法化后的文件名,冲突时在末尾叠加 _2、_3 …
## Assets 分组:严格按 assets 根下的目录层级生成 Group ID,各层级大写并用下划线连接。

const SCENE_ROOTS: PackedStringArray = ["res://src/game/scenes"]
const UI_ROOTS: PackedStringArray = ["res://src/game/ui"]
const ASSET_ROOTS: PackedStringArray = ["res://src/assets"]
const RESOURCE_ROOTS: PackedStringArray = ["res://src/resource"]

const _ASSET_EXTENSIONS: PackedStringArray = [
	"png", "jpg", "jpeg", "webp", "svg", "bmp", "tga",
	"wav", "ogg", "mp3",
	"ttf", "otf", "woff", "woff2",
	"glb", "gltf", "obj", "fbx",
	"atlas", "bin", "dat", "json", "csv", "txt",
	"tres", "res", "material", "shader", "gdshader",
]

#region Public API
## 扫描默认目录并追加到 manifest,返回本次导入统计。
static func import_into(manifest: EditAssetManifest) -> Dictionary:
	var scene_paths := _collect_paths(manifest.scenes, "scene_path")
	var ui_paths := _collect_paths(manifest.uis, "scene_path")
	var asset_paths := _collect_paths(manifest.assets, "path")
	var resource_paths := _collect_paths(manifest.resources, "path")

	var scene_ids := _collect_ids(manifest.scenes)
	var ui_ids := _collect_ids(manifest.uis)
	var asset_ids := _collect_ids(manifest.assets)
	var resource_ids := _collect_ids(manifest.resources)

	var added_scenes := 0
	var added_uis := 0
	var added_assets := 0
	var added_resources := 0
	var skipped := 0

	for root in SCENE_ROOTS:
		for path in _scan_tscn(root):
			if scene_paths.has(path):
				skipped += 1
				continue
			var entry := EditSceneEntry.new()
			entry.id = _allocate_id(path.get_file().get_basename(), scene_ids)
			entry.scene_path = path
			manifest.scenes.append(entry)
			scene_paths[path] = true
			added_scenes += 1

	for root in UI_ROOTS:
		for path in _scan_tscn(root):
			if ui_paths.has(path):
				skipped += 1
				continue
			var entry := EditUIEntry.new()
			entry.id = _allocate_id(path.get_file().get_basename(), ui_ids)
			entry.scene_path = path
			manifest.uis.append(entry)
			ui_paths[path] = true
			added_uis += 1

	for root in ASSET_ROOTS:
		for path in _scan_assets(root):
			if asset_paths.has(path):
				skipped += 1
				continue
			if _is_asset_root_file(root, path):
				push_error(
					"Asset Groups scan: assets must be placed under a subdirectory of src/assets/, not at root: %s"
					% path
				)
				skipped += 1
				continue
			var group_name := _asset_group_from_path(root, path)
			var entry := EditAssetEntry.new()
			entry.id = _allocate_id(path.get_file().get_basename(), asset_ids)
			entry.path = path
			entry.group = group_name
			manifest.add_asset_group(group_name)
			manifest.assets.append(entry)
			asset_paths[path] = true
			added_assets += 1

	for root in RESOURCE_ROOTS:
		for path in _scan_assets(root):
			if path.begins_with("res://src/resource/data/") or path.begins_with("res://src/resource/generated/"):
				continue
			if resource_paths.has(path):
				skipped += 1
				continue
			if _is_asset_root_file(root, path):
				push_error(
					"Asset Groups scan: resources must be placed under a subdirectory of src/resource/, not at root: %s"
					% path
				)
				skipped += 1
				continue
			var group_name := _asset_group_from_path(root, path)
			var entry := EditResourceEntry.new()
			entry.id = _allocate_id(path.get_file().get_basename(), resource_ids)
			entry.path = path
			entry.group = group_name
			manifest.add_resource_group(group_name)
			manifest.resources.append(entry)
			resource_paths[path] = true
			added_resources += 1

	return {
		"added_scenes": added_scenes,
		"added_uis": added_uis,
		"added_assets": added_assets,
		"added_resources": added_resources,
		"skipped": skipped,
	}
#endregion

#region Scanning
static func _scan_tscn(root: String) -> PackedStringArray:
	var results: PackedStringArray = []
	if DirAccess.open(root) == null:
		return results
	_scan_dir(root, PackedStringArray(["tscn"]), results)
	results.sort()
	return results


static func _scan_assets(root: String) -> PackedStringArray:
	var results: PackedStringArray = []
	if DirAccess.open(root) == null:
		return results
	_scan_dir(root, _ASSET_EXTENSIONS, results)
	results.sort()
	return results


static func _scan_dir(dir_path: String, extensions: PackedStringArray, out: PackedStringArray) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		if sub.begins_with("."):
			continue
		_scan_dir("%s/%s" % [dir_path, sub], extensions, out)
	for file_name in dir.get_files():
		if file_name.ends_with(".import") or file_name.ends_with(".uid"):
			continue
		var ext := file_name.get_extension().to_lower()
		if ext not in extensions:
			continue
		out.append("%s/%s" % [dir_path, file_name])
#endregion

#region Id & path helpers
static func _collect_paths(entries: Array, path_prop: StringName) -> Dictionary:
	var index: Dictionary = {}
	for entry in entries:
		var path: String = entry.get(path_prop)
		if not path.is_empty():
			index[path] = true
	return index


static func _collect_ids(entries: Array) -> Dictionary:
	var used: Dictionary = {}
	for entry in entries:
		var id: StringName = entry.id
		if id != &"":
			used[String(id)] = true
	return used


static func _allocate_id(base: String, used: Dictionary) -> StringName:
	var legal_base := AssetGroupsGeneratorUtils.legalize_identifier(base)
	var candidate := legal_base
	var n := 1
	while used.has(candidate):
		n += 1
		candidate = "%s_%d" % [legal_base, n]
	used[candidate] = true
	return StringName(candidate)


## 文件是否直接落在 assets 根目录(相对路径无子文件夹)。
static func _is_asset_root_file(asset_root: String, path: String) -> bool:
	var normalized_root := asset_root.trim_suffix("/")
	var relative := path.trim_prefix("%s/" % normalized_root)
	return not relative.contains("/")


## 按 assets 根下的完整目录层级生成组名,各段合法化后转大写并用下划线连接。
## 如 textures/entities/config/country_catalog/AD.webp → TEXTURES_ENTITIES_CONFIG_COUNTRY_CATALOG。
static func _asset_group_from_path(asset_root: String, path: String) -> StringName:
	var normalized_root := asset_root.trim_suffix("/")
	var relative := path.trim_prefix("%s/" % normalized_root)
	var dir_relative := relative.get_base_dir()
	if dir_relative.is_empty():
		return &""

	var segments: PackedStringArray = []
	for segment in dir_relative.split("/", false):
		segments.append(AssetGroupsGeneratorUtils.legalize_identifier(segment).to_upper())
	return StringName("_".join(segments))
#endregion
