@tool
class_name AssetGroupTreeBuilder
extends RefCounted

## 将扁平 group 名(下划线分段)整理为树形目录,供 [AssetGroupTreeController] 渲染。

class FolderNode:
	var segment: String = ""
	## 树节点展示名:取自 assets 目录下的真实文件夹名;无路径映射时回退为 [member segment]。
	var display_segment: String = ""
	var full_name: String = ""
	var children: Dictionary = {} ## segment -> FolderNode
	var assets: Array[EditAssetEntry] = []


static func build(manifest: EditAssetManifest) -> FolderNode:
	var root := FolderNode.new()
	if manifest == null:
		return root

	var display_map := _build_folder_display_map(manifest)
	var registered: Dictionary = {}
	for group_name in manifest.collect_asset_groups():
		registered[group_name] = true

	for group_name in registered.keys():
		_insert_path(root, group_name.split("_", false), display_map)

	for entry in manifest.assets:
		if entry.group == &"":
			continue
		var group_text := String(entry.group)
		var node := _insert_path(root, group_text.split("_", false), display_map)
		if node != null:
			node.assets.append(entry)

	_dedupe_assets(root)
	return root


## 从资产路径推导各层级文件夹的展示名;[code]full_name[/code] 仍为大写 Group ID。
static func _build_folder_display_map(manifest: EditAssetManifest) -> Dictionary:
	var labels: Dictionary = {}
	if manifest == null:
		return labels

	var assets_root := ManifestScanner.ASSET_ROOTS[0].trim_suffix("/")
	for entry in manifest.assets:
		if entry.path.is_empty() or not entry.path.begins_with("%s/" % assets_root):
			continue
		var relative := entry.path.trim_prefix("%s/" % assets_root)
		var dir_relative := relative.get_base_dir()
		if dir_relative.is_empty():
			continue

		var group_parts: PackedStringArray = []
		for folder_name in dir_relative.split("/", false):
			if folder_name.is_empty():
				continue
			var segment_key := AssetGroupsGeneratorUtils.legalize_identifier(folder_name).to_upper()
			group_parts.append(segment_key)
			var full_name := "_".join(group_parts)
			labels[full_name] = folder_name

	return labels


static func sorted_child_segments(folder: FolderNode) -> PackedStringArray:
	var keys: PackedStringArray = []
	for key in folder.children.keys():
		keys.append(String(key))
	keys.sort()
	return keys


static func folder_is_empty(folder: FolderNode) -> bool:
	if not folder.assets.is_empty():
		return false
	for child in folder.children.values():
		if not folder_is_empty(child):
			return false
	return true


static func is_manageable_group(manifest: EditAssetManifest, group_name: StringName) -> bool:
	if manifest == null:
		return false
	if group_name == &"":
		return false
	if manifest.groups.has(group_name):
		return true
	return not manifest.assets_in_group(group_name).is_empty()


static func _insert_path(
	root: FolderNode, segments: PackedStringArray, display_map: Dictionary
) -> FolderNode:
	if segments.is_empty():
		return null

	var current := root
	var path_parts: PackedStringArray = []
	for segment in segments:
		if segment.is_empty():
			continue
		path_parts.append(segment)
		if not current.children.has(segment):
			var child := FolderNode.new()
			child.segment = segment
			current.children[segment] = child
		current = current.children[segment]
		current.full_name = "_".join(path_parts)
		if display_map.has(current.full_name):
			current.display_segment = display_map[current.full_name]
		elif current.display_segment.is_empty():
			current.display_segment = segment
	return current


static func _dedupe_assets(folder: FolderNode) -> void:
	var seen: Dictionary = {}
	var unique: Array[EditAssetEntry] = []
	for entry in folder.assets:
		if entry == null or seen.has(entry):
			continue
		seen[entry] = true
		unique.append(entry)
	folder.assets = unique

	for child in folder.children.values():
		_dedupe_assets(child)
