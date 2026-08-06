@tool
class_name AccessorsGenerator
extends RefCounted

## 把 manifest 可生成条目写成框架运行时查表类 [Scenes] / [Uis] / [Assets]。
## 生成物遵循 docs/conventions/coding-style.md:#region、静态类型、英文 ## 文档。

const _SCENES_PATH := "res://src/resource/generated/scenes.gd"
const _UIS_PATH := "res://src/resource/generated/uis.gd"
const _ASSETS_PATH := "res://src/resource/generated/assets.gd"
const _RESOURCES_PATH := "res://src/resource/generated/resources.gd"
const _ASSETS_ROOT := "res://src/assets"
const _RESOURCE_ROOT := "res://src/resource"

#region Public API
## 生成并保存查表类,返回 [code]{ errors, written_paths }[/code]。
static func generate_and_save(
	manifest: EditAssetManifest,
	flags: GenerateFlags = null
) -> Dictionary:
	AssetGroupsGeneratorUtils.begin_resolve_batch()
	var errors := PackedStringArray()
	var written_paths := PackedStringArray()
	if flags == null:
		flags = GenerateFlags.new()

	if flags.scenes_accessor:
		var scene_err := AssetGroupsGeneratorUtils.write_text(_SCENES_PATH, _build_scenes(manifest))
		if scene_err != "":
			errors.append(scene_err)
		else:
			written_paths.append(_SCENES_PATH)

	if flags.uis_accessor:
		var ui_err := AssetGroupsGeneratorUtils.write_text(_UIS_PATH, _build_uis(manifest))
		if ui_err != "":
			errors.append(ui_err)
		else:
			written_paths.append(_UIS_PATH)

	if flags.assets_accessor:
		var asset_err := AssetGroupsGeneratorUtils.write_text(_ASSETS_PATH, _build_assets(manifest))
		if asset_err != "":
			errors.append(asset_err)
		else:
			written_paths.append(_ASSETS_PATH)

	if flags.resources_accessor:
		var res_err := AssetGroupsGeneratorUtils.write_text(_RESOURCES_PATH, _build_resources(manifest))
		if res_err != "":
			errors.append(res_err)
		else:
			written_paths.append(_RESOURCES_PATH)

	return {"errors": errors, "written_paths": written_paths}


static func output_paths() -> PackedStringArray:
	return PackedStringArray([_SCENES_PATH, _UIS_PATH, _ASSETS_PATH, _RESOURCES_PATH])
#endregion

#region Scenes
static func _build_scenes(manifest: EditAssetManifest) -> String:
	var entries := _sorted_by_id(ManifestEntries.complete_scenes(manifest))
	var const_lines := PackedStringArray()
	var table_lines := PackedStringArray()
	for entry in entries:
		var name := AssetGroupsGeneratorUtils.const_name(entry.id)
		var uid := AssetGroupsGeneratorUtils.resolve_load_key(entry.scene_path)
		const_lines.append("const %s: StringName = &\"%s\"" % [name, entry.id])
		table_lines.append(_scene_table_row(name, uid, entry.scene_path))
	return _assemble(
		"Scenes",
		"## Static scene id registry. Use [Scenes] constants instead of raw string ids.",
		"res://src/resource/data/scene_registry.tres",
		const_lines,
		"## Registered scenes: id -> { uid, path }.",
		table_lines,
		PackedStringArray(),
		_scenes_public_api(),
	)
#endregion

#region UIs
static func _build_uis(manifest: EditAssetManifest) -> String:
	var entries := _sorted_by_id(ManifestEntries.complete_uis(manifest))
	var const_lines := PackedStringArray()
	var table_lines := PackedStringArray()
	for entry in entries:
		var name := AssetGroupsGeneratorUtils.const_name(entry.id)
		var uid := AssetGroupsGeneratorUtils.resolve_load_key(entry.scene_path)
		var layer_key: String = String(RuntimeUIEntry.Layer.keys()[int(entry.layer)])
		var cache_key: String = String(RuntimeUIEntry.Cache.keys()[int(entry.cache)])
		const_lines.append("const %s: StringName = &\"%s\"" % [name, entry.id])
		table_lines.append(_ui_table_row(name, uid, entry.scene_path, layer_key, cache_key))
	return _assemble(
		"Uis",
		"## Static UI id registry. Use [Uis] constants instead of raw string ids.",
		"res://src/resource/data/ui_registry.tres",
		const_lines,
		"## Registered UIs: id -> { uid, path, layer, cache }.",
		table_lines,
		PackedStringArray(),
		_uis_public_api(),
	)
#endregion

#region Assets
static func _build_assets(manifest: EditAssetManifest) -> String:
	var entries := _sorted_by_path(ManifestEntries.complete_assets(manifest))
	var by_group: Dictionary = {}
	for entry: EditAssetEntry in entries:
		var group_name: StringName = entry.group
		if group_name == &"":
			continue
		if not by_group.has(group_name):
			var group_bucket: Array[EditAssetEntry] = []
			by_group[group_name] = group_bucket
		(by_group[group_name] as Array[EditAssetEntry]).append(entry)

	var emitted_consts: Dictionary = {}
	var section_lines := PackedStringArray()
	var group_paths: Dictionary = {}
	var group_by_filename: Dictionary = {}

	var group_names: Array = by_group.keys()
	group_names.sort_custom(func(a, b) -> bool: return String(a) < String(b))

	for group_name in group_names:
		var group_entries: Array[EditAssetEntry] = by_group[group_name]
		section_lines.append("#region %s" % String(group_name))

		var dir_paths := _collect_group_dir_paths(group_entries, _ASSETS_ROOT)
		for dir_path in dir_paths:
			var dir_const := _dir_const_name(dir_path, _ASSETS_ROOT)
			if dir_const.is_empty() or emitted_consts.has(dir_const):
				continue
			emitted_consts[dir_const] = true
			section_lines.append('const %s := "%s"' % [dir_const, dir_path])

		var paths_in_group := PackedStringArray()
		var filename_index: Dictionary = {}
		for entry: EditAssetEntry in group_entries:
			var file_const := _file_const_name(entry.path, emitted_consts)
			emitted_consts[file_const] = true
			section_lines.append('const %s := "%s"' % [file_const, entry.path])
			paths_in_group.append(entry.path)
			var leaf_name := entry.path.get_file()
			if not filename_index.has(leaf_name):
				filename_index[leaf_name] = entry.path

		group_paths[group_name] = paths_in_group
		group_by_filename[group_name] = filename_index
		section_lines.append("#endregion")
		section_lines.append("")

	return _assemble_assets(section_lines, group_paths, group_by_filename)


static func _collect_group_dir_paths(entries: Array, assets_root: String) -> PackedStringArray:
	var normalized_root := assets_root.trim_suffix("/") + "/"
	var seen: Dictionary = {}
	var dirs: Array[String] = []
	for entry in entries:
		var entry_path: String = entry.path
		var dir_path := _normalize_dir(entry_path.get_base_dir())
		while dir_path.begins_with(normalized_root) and dir_path != normalized_root:
			if not seen.has(dir_path):
				seen[dir_path] = true
				dirs.append(dir_path)
			var trimmed := dir_path.trim_suffix("/")
			dir_path = _normalize_dir(trimmed.get_base_dir())

	dirs.sort_custom(func(a: String, b: String) -> bool:
		if a.length() == b.length():
			return a < b
		return a.length() < b.length()
	)
	var result := PackedStringArray()
	for dir_path in dirs:
		result.append(dir_path)
	return result


static func _normalize_dir(dir_path: String) -> String:
	if dir_path.is_empty():
		return ""
	return dir_path if dir_path.ends_with("/") else dir_path + "/"


static func _dir_const_name(dir_path: String, assets_root: String) -> String:
	var normalized_root := assets_root.trim_suffix("/") + "/"
	var relative := dir_path.trim_prefix(normalized_root).trim_suffix("/")
	if relative.is_empty():
		return ""
	var segments: PackedStringArray = []
	for segment in relative.split("/", false):
		segments.append(AssetGroupsGeneratorUtils.legalize_identifier(segment).to_upper())
	return "_".join(segments)


static func _file_const_name(path: String, emitted_consts: Dictionary) -> String:
	var base := AssetGroupsGeneratorUtils.legalize_identifier(path.get_file().get_basename())
	var candidate := base.to_upper()
	if not emitted_consts.has(candidate):
		return candidate
	var suffix := 2
	while emitted_consts.has("%s_%d" % [candidate, suffix]):
		suffix += 1
	return "%s_%d" % [candidate, suffix]


## Generate 校验用:与 [method _build_assets] 相同的文件名常量命名规则。
static func file_const_name_for_path(path: String, emitted_consts: Dictionary) -> String:
	return _file_const_name(path, emitted_consts)


static func _assemble_assets(
	section_lines: PackedStringArray,
	group_paths: Dictionary,
	group_by_filename: Dictionary,
) -> String:
	var lines := PackedStringArray([
		"class_name Assets",
		"extends RefCounted",
		"",
		"## -----------------------------------------------------------------------------",
		"## AUTO-GENERATED FILE. DO NOT EDIT.",
		"## Generator : Asset Groups",
		"## Source    : res://src/resource/data/asset_map.tres",
		"##",
		"## Edit the source manifest in Asset Groups and regenerate this file.",
		"## Any manual changes will be overwritten.",
		"## -----------------------------------------------------------------------------",
		"",
		"## Static asset path registry. Use [Assets] constants instead of raw [code]res://[/code] strings.",
		"",
		"#region Constants & State",
	])
	lines.append_array(section_lines)
	lines.append("## Group -> file paths (leaf assets only, dirs excluded).")
	lines.append("const _GROUP_PATHS: Dictionary = {")
	var group_names: Array = group_paths.keys()
	group_names.sort_custom(func(a, b) -> bool: return String(a) < String(b))
	for group_name in group_names:
		var paths: PackedStringArray = group_paths[group_name]
		var quoted: PackedStringArray = []
		for path in paths:
			quoted.append('"%s"' % path)
		lines.append('\t&"%s": [%s],' % [group_name, ", ".join(quoted)])
	lines.append("}")
	lines.append("")
	lines.append("## Group -> leaf filename -> first matching file path.")
	lines.append("const _GROUP_BY_FILENAME: Dictionary = {")
	for group_name in group_names:
		var filename_index: Dictionary = group_by_filename[group_name]
		var file_names: Array = filename_index.keys()
		file_names.sort()
		lines.append('\t&"%s": {' % group_name)
		for leaf_name in file_names:
			lines.append('\t\t"%s": "%s",' % [leaf_name, filename_index[leaf_name]])
		lines.append("\t},")
	lines.append("}")
	lines.append("#endregion")
	lines.append("")
	lines.append("#region Public API")
	lines.append_array(_assets_public_api())
	lines.append("#endregion")
	lines.append("")
	return "\n".join(lines)
#endregion

#region Generated API Templates
static func _scenes_public_api() -> PackedStringArray:
	return PackedStringArray([
		"## Returns whether [param id] is registered.",
		"static func has_id(id: StringName) -> bool:",
		"\treturn _TABLE.has(id)",
		"",
		"## Returns every registered scene id.",
		"static func ids() -> Array:",
		"\treturn _TABLE.keys()",
		"",
		"## Returns the ResourceLoader key ([code]uid://[/code]) for [param id].",
		"## Returns an empty string when [param id] is unknown.",
		"static func load_path(id: StringName) -> String:",
		"\tvar entry: Dictionary = _TABLE.get(id, {})",
		"\treturn String(entry.get(\"uid\", \"\"))",
		"",
		"## Returns the source file path for [param id] (logging only).",
		"## Returns an empty string when [param id] is unknown.",
		"static func file_path(id: StringName) -> String:",
		"\tvar entry: Dictionary = _TABLE.get(id, {})",
		"\treturn String(entry.get(\"path\", \"\"))",
	])


static func _uis_public_api() -> PackedStringArray:
	return PackedStringArray([
		"## Returns whether [param id] is registered.",
		"static func has_id(id: StringName) -> bool:",
		"\treturn _TABLE.has(id)",
		"",
		"## Returns every registered UI id.",
		"static func ids() -> Array:",
		"\treturn _TABLE.keys()",
		"",
		"## Returns the ResourceLoader key ([code]uid://[/code]) for [param id].",
		"## Returns an empty string when [param id] is unknown.",
		"static func load_path(id: StringName) -> String:",
		"\tvar entry: Dictionary = _TABLE.get(id, {})",
		"\treturn String(entry.get(\"uid\", \"\"))",
		"",
		"## Returns the source file path for [param id] (logging only).",
		"## Returns an empty string when [param id] is unknown.",
		"static func file_path(id: StringName) -> String:",
		"\tvar entry: Dictionary = _TABLE.get(id, {})",
		"\treturn String(entry.get(\"path\", \"\"))",
		"",
		"## Returns the render layer for [param id].",
		"## Falls back to [code]RuntimeUIEntry.Layer.WINDOW[/code] when unknown.",
		"static func layer(id: StringName) -> RuntimeUIEntry.Layer:",
		"\tvar entry: Dictionary = _TABLE.get(id, {})",
		"\tvar value: int = entry.get(\"layer\", RuntimeUIEntry.Layer.WINDOW)",
		"\treturn value as RuntimeUIEntry.Layer",
		"",
		"## Returns the cache policy for [param id].",
		"## Falls back to [code]RuntimeUIEntry.Cache.DESTROY[/code] when unknown.",
		"static func cache(id: StringName) -> RuntimeUIEntry.Cache:",
		"\tvar entry: Dictionary = _TABLE.get(id, {})",
		"\tvar value: int = entry.get(\"cache\", RuntimeUIEntry.Cache.DESTROY)",
		"\treturn value as RuntimeUIEntry.Cache",
	])


static func _assets_public_api() -> PackedStringArray:
	return PackedStringArray([
		"## Returns every file path registered under [param group_name].",
		"static func paths_in_group(group_name: StringName) -> Array[String]:",
		"\tvar raw: Array = _GROUP_PATHS.get(group_name, [])",
		"\tvar result: Array[String] = []",
		"\tfor path in raw:",
		"\t\tresult.append(String(path))",
		"\treturn result",
		"",
		"## Returns the first file path in [param group_name] whose leaf filename equals [param filename].",
		"## [param filename] must be the full leaf name (e.g. [code]01-01.png[/code]).",
		"static func find_path_by_filename(group_name: StringName, filename: String) -> String:",
		"\tvar index: Dictionary = _GROUP_BY_FILENAME.get(group_name, {})",
		"\treturn String(index.get(filename, \"\"))",
	])
#endregion

#region Helpers
static func _sorted_by_id(entries: Array) -> Array:
	var sorted := entries.duplicate()
	sorted.sort_custom(func(a, b) -> bool: return String(a.id) < String(b.id))
	return sorted


static func _sorted_by_path(entries: Array) -> Array:
	var sorted := entries.duplicate()
	sorted.sort_custom(func(a, b) -> bool: return a.path < b.path)
	return sorted


static func _scene_table_row(const_name: String, uid: String, path: String) -> String:
	return (
		"\t%s: {\n\t\t\"uid\": \"%s\",\n\t\t\"path\": \"%s\",\n\t}," % [const_name, uid, path]
	)


static func _ui_table_row(
	const_name: String,
	uid: String,
	path: String,
	layer_key: String,
	cache_key: String,
) -> String:
	return (
		"\t%s: {\n"
		+ "\t\t\"uid\": \"%s\",\n"
		+ "\t\t\"path\": \"%s\",\n"
		+ "\t\t\"layer\": RuntimeUIEntry.Layer.%s,\n"
		+ "\t\t\"cache\": RuntimeUIEntry.Cache.%s,\n"
		+ "\t},"
	) % [const_name, uid, path, layer_key, cache_key]


static func _assemble(
	class_name_text: String,
	class_doc: String,
	data_path: String,
	id_const_lines: PackedStringArray,
	table_doc: String,
	table_lines: PackedStringArray,
	mid_constants: PackedStringArray,
	public_api_lines: PackedStringArray,
) -> String:
	var lines := PackedStringArray([
		"class_name %s" % class_name_text,
		"extends RefCounted",
		"",
		"## -----------------------------------------------------------------------------",
		"## AUTO-GENERATED FILE. DO NOT EDIT.",
		"## Generator : Asset Groups",
		"## Source    : %s" % data_path,
		"##",
		"## Edit the source manifest in Asset Groups and regenerate this file.",
		"## Any manual changes will be overwritten.",
		"## -----------------------------------------------------------------------------",
		"",
		class_doc,
		"",
		"#region Constants & State",
	])
	lines.append_array(id_const_lines)
	if not id_const_lines.is_empty():
		lines.append("")
	lines.append(table_doc)
	lines.append("const _TABLE: Dictionary = {")
	lines.append_array(table_lines)
	lines.append("}")
	lines.append_array(mid_constants)
	lines.append("#endregion")
	lines.append("")
	lines.append("#region Public API")
	lines.append_array(public_api_lines)
	lines.append("#endregion")
	lines.append("")
	return "\n".join(lines)
#region Resources
static func _build_resources(manifest: EditAssetManifest) -> String:
	var entries := _sorted_by_path(ManifestEntries.complete_resources(manifest))
	var by_group: Dictionary = {}
	for entry: EditResourceEntry in entries:
		var group_name: StringName = entry.group
		if group_name == &"":
			continue
		if not by_group.has(group_name):
			var group_bucket: Array[EditResourceEntry] = []
			by_group[group_name] = group_bucket
		(by_group[group_name] as Array[EditResourceEntry]).append(entry)

	var emitted_consts: Dictionary = {}
	var section_lines := PackedStringArray()
	var group_paths: Dictionary = {}
	var group_by_filename: Dictionary = {}

	var group_names: Array = by_group.keys()
	group_names.sort_custom(func(a, b) -> bool: return String(a) < String(b))

	for group_name in group_names:
		var group_entries: Array[EditResourceEntry] = by_group[group_name]
		section_lines.append("#region %s" % String(group_name))

		var dir_paths := _collect_group_dir_paths(group_entries, _RESOURCE_ROOT)
		for dir_path in dir_paths:
			var dir_const := _dir_const_name(dir_path, _RESOURCE_ROOT)
			if dir_const.is_empty() or emitted_consts.has(dir_const):
				continue
			emitted_consts[dir_const] = true
			section_lines.append('const %s := "%s"' % [dir_const, dir_path])

		var paths_in_group := PackedStringArray()
		var filename_index: Dictionary = {}
		for entry: EditResourceEntry in group_entries:
			var file_const := _file_const_name(entry.path, emitted_consts)
			emitted_consts[file_const] = true
			section_lines.append('const %s := "%s"' % [file_const, entry.path])
			paths_in_group.append(entry.path)
			var leaf_name := entry.path.get_file()
			if not filename_index.has(leaf_name):
				filename_index[leaf_name] = entry.path

		group_paths[group_name] = paths_in_group
		group_by_filename[group_name] = filename_index
		section_lines.append("#endregion")
		section_lines.append("")

	return _assemble_resources(section_lines, group_paths, group_by_filename)


static func _assemble_resources(
	section_lines: PackedStringArray,
	group_paths: Dictionary,
	group_by_filename: Dictionary,
) -> String:
	var lines := PackedStringArray([
		"class_name Resources",
		"extends RefCounted",
		"",
		"## -----------------------------------------------------------------------------",
		"## AUTO-GENERATED FILE. DO NOT EDIT.",
		"## Generator : Asset Groups",
		"## Source    : res://src/resource/data/resource_map.tres",
		"##",
		"## Edit the source manifest in Asset Groups and regenerate this file.",
		"## Any manual changes will be overwritten.",
		"## -----------------------------------------------------------------------------",
		"",
		"## Static resource path registry. Use [Resources] constants instead of raw [code]res://[/code] strings.",
		"",
		"#region Constants & State",
	])
	lines.append_array(section_lines)
	lines.append("## Group -> file paths (leaf assets only, dirs excluded).")
	lines.append("const _GROUP_PATHS: Dictionary = {")
	var group_names: Array = group_paths.keys()
	group_names.sort_custom(func(a, b) -> bool: return String(a) < String(b))
	for group_name in group_names:
		var paths: PackedStringArray = group_paths[group_name]
		var quoted: PackedStringArray = []
		for path in paths:
			quoted.append('"%s"' % path)
		lines.append('\t&"%s": [%s],' % [group_name, ", ".join(quoted)])
	lines.append("}")
	lines.append("")
	lines.append("## Group -> leaf filename -> first matching file path.")
	lines.append("const _GROUP_BY_FILENAME: Dictionary = {")
	for group_name in group_names:
		var filename_index: Dictionary = group_by_filename[group_name]
		var file_names: Array = filename_index.keys()
		file_names.sort()
		lines.append('\t&"%s": {' % group_name)
		for leaf_name in file_names:
			lines.append('\t\t"%s": "%s",' % [leaf_name, filename_index[leaf_name]])
		lines.append("\t},")
	lines.append("}")
	lines.append("#endregion")
	lines.append("")
	lines.append("#region Public API")
	lines.append_array(_resources_public_api())
	lines.append("#endregion")
	lines.append("")
	return "\n".join(lines)


static func _resources_public_api() -> PackedStringArray:
	return _assets_public_api()
#endregion
