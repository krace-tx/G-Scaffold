@tool
class_name ManifestScanner
extends RefCounted

## 扫描项目目录,把尚未登记的 .tscn / 媒体资源导入 [AssetManifest]。
## 只追加、不覆盖已有路径;id 取文件名,冲突时在末尾叠加 _2、_3 …

const SCENE_ROOTS: PackedStringArray = ["res://src/game/scenes"]
const UI_ROOTS: PackedStringArray = ["res://src/game/ui"]
const ASSET_ROOTS: PackedStringArray = ["res://src/assets"]

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
static func import_into(manifest: AssetManifest) -> Dictionary:
	var scene_paths := _collect_paths(manifest.scenes, "scene_path")
	var ui_paths := _collect_paths(manifest.uis, "scene_path")
	var asset_paths := _collect_paths(manifest.assets, "path")

	var scene_ids := _collect_ids(manifest.scenes)
	var ui_ids := _collect_ids(manifest.uis)
	var asset_ids := _collect_ids(manifest.assets)

	var added_scenes := 0
	var added_uis := 0
	var added_assets := 0
	var skipped := 0

	for root in SCENE_ROOTS:
		for path in _scan_tscn(root):
			if scene_paths.has(path):
				skipped += 1
				continue
			var entry := SceneEntry.new()
			entry.id = _allocate_id(path.get_file().get_basename(), scene_ids)
			entry.scene_path = path
			entry.asset_group = &""
			manifest.scenes.append(entry)
			scene_paths[path] = true
			added_scenes += 1

	for root in UI_ROOTS:
		for path in _scan_tscn(root):
			if ui_paths.has(path):
				skipped += 1
				continue
			var entry := UIEntry.new()
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
			var entry := AssetEntry.new()
			entry.id = _allocate_id(path.get_file().get_basename(), asset_ids)
			entry.path = path
			entry.group = &""
			manifest.assets.append(entry)
			asset_paths[path] = true
			added_assets += 1

	return {
		"added_scenes": added_scenes,
		"added_uis": added_uis,
		"added_assets": added_assets,
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
	if base.is_empty():
		base = "unnamed"
	var candidate := base
	var n := 1
	while used.has(candidate):
		n += 1
		candidate = "%s_%d" % [base, n]
	used[candidate] = true
	return StringName(candidate)
#endregion
