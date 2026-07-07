@tool
class_name AccessorsGenerator
extends RefCounted

## 把 manifest 可生成条目写成框架运行时查表类 [Scenes] / [Uis] / [Assets]。
## 空清单也会写出带空 [code]_TABLE[/code] 的模板,供 Service 静态引用。

const _SCENES_PATH := "res://src/resource/generated/scenes.gd"
const _UIS_PATH := "res://src/resource/generated/uis.gd"
const _ASSETS_PATH := "res://src/resource/generated/assets.gd"

#region Public API
static func generate_and_save(manifest: AssetManifest) -> PackedStringArray:
	var errors := PackedStringArray()

	var scene_err := GeneratorUtils.write_text(_SCENES_PATH, _build_scenes(manifest))
	if scene_err != "":
		errors.append(scene_err)

	var ui_err := GeneratorUtils.write_text(_UIS_PATH, _build_uis(manifest))
	if ui_err != "":
		errors.append(ui_err)

	var asset_err := GeneratorUtils.write_text(_ASSETS_PATH, _build_assets(manifest))
	if asset_err != "":
		errors.append(asset_err)

	return errors
#endregion

#region Scenes
static func _build_scenes(manifest: AssetManifest) -> String:
	var entries := _sorted_by_id(ManifestEntries.complete_scenes(manifest))
	var const_lines := PackedStringArray()
	var table_lines := PackedStringArray()
	for entry in entries:
		var name := GeneratorUtils.const_name(entry.id)
		var uid := GeneratorUtils.resolve_load_key(entry.scene_path)
		const_lines.append("const %s: StringName = &\"%s\"" % [name, entry.id])
		table_lines.append(
			"\t%s: { \"uid\": \"%s\", \"path\": \"%s\", \"group\": &\"%s\" }," % [
				name, uid, entry.scene_path, entry.asset_group,
			]
		)
	return _assemble(
		"Scenes",
		"res://src/resource/data/scene_registry.tres",
		const_lines,
		PackedStringArray([
			"## id → { uid(加载键), path(仅日志/可读性), group(资产分组) }。",
			"const _TABLE: Dictionary = {",
		]),
		table_lines,
		PackedStringArray([
			"}",
			"",
			"static func has_id(id: StringName) -> bool:",
			"\treturn _TABLE.has(id)",
			"",
			"static func ids() -> Array:",
			"\treturn _TABLE.keys()",
			"",
			"## ResourceLoader 可用的加载键(uid://);未登记返回空字符串。",
			"static func load_path(id: StringName) -> String:",
			"\tvar entry: Dictionary = _TABLE.get(id, {})",
			"\treturn String(entry.get(\"uid\", \"\"))",
			"",
			"## 人类可读的源文件路径(日志用);未登记返回空字符串。",
			"static func file_path(id: StringName) -> String:",
			"\tvar entry: Dictionary = _TABLE.get(id, {})",
			"\treturn String(entry.get(\"path\", \"\"))",
			"",
			"## 本场景关联的资产分组;未登记或无分组返回 &\"\"。",
			"static func asset_group(id: StringName) -> StringName:",
			"\tvar entry: Dictionary = _TABLE.get(id, {})",
			"\treturn StringName(entry.get(\"group\", &\"\"))",
		]),
	)
#endregion

#region UIs
static func _build_uis(manifest: AssetManifest) -> String:
	var entries := _sorted_by_id(ManifestEntries.complete_uis(manifest))
	var const_lines := PackedStringArray()
	var table_lines := PackedStringArray()
	for entry in entries:
		var name := GeneratorUtils.const_name(entry.id)
		var uid := GeneratorUtils.resolve_load_key(entry.scene_path)
		var layer_key: String = String(UIRegistryEntry.Layer.keys()[int(entry.layer)])
		var cache_key: String = String(UIRegistryEntry.Cache.keys()[int(entry.cache)])
		const_lines.append("const %s: StringName = &\"%s\"" % [name, entry.id])
		table_lines.append(
			"\t%s: { \"uid\": \"%s\", \"path\": \"%s\", \"layer\": UIRegistryEntry.Layer.%s, \"cache\": UIRegistryEntry.Cache.%s }," % [
				name, uid, entry.scene_path, layer_key, cache_key,
			]
		)
	return _assemble(
		"Uis",
		"res://src/resource/data/ui_registry.tres",
		const_lines,
		PackedStringArray([
			"## id → { uid(加载键), path(仅日志/可读性), layer(渲染层), cache(缓存策略) }。",
			"const _TABLE: Dictionary = {",
		]),
		table_lines,
		PackedStringArray([
			"}",
			"",
			"static func has_id(id: StringName) -> bool:",
			"\treturn _TABLE.has(id)",
			"",
			"static func ids() -> Array:",
			"\treturn _TABLE.keys()",
			"",
			"static func load_path(id: StringName) -> String:",
			"\tvar entry: Dictionary = _TABLE.get(id, {})",
			"\treturn String(entry.get(\"uid\", \"\"))",
			"",
			"static func file_path(id: StringName) -> String:",
			"\tvar entry: Dictionary = _TABLE.get(id, {})",
			"\treturn String(entry.get(\"path\", \"\"))",
			"",
			"static func layer(id: StringName) -> UIRegistryEntry.Layer:",
			"\tvar entry: Dictionary = _TABLE.get(id, {})",
			"\tvar value: int = entry.get(\"layer\", UIRegistryEntry.Layer.WINDOW)",
			"\treturn value as UIRegistryEntry.Layer",
			"",
			"static func cache(id: StringName) -> UIRegistryEntry.Cache:",
			"\tvar entry: Dictionary = _TABLE.get(id, {})",
			"\tvar value: int = entry.get(\"cache\", UIRegistryEntry.Cache.DESTROY)",
			"\treturn value as UIRegistryEntry.Cache",
		]),
	)
#endregion

#region Assets
static func _build_assets(manifest: AssetManifest) -> String:
	var entries := _sorted_by_id(ManifestEntries.complete_assets(manifest))
	var const_lines := PackedStringArray()
	var table_lines := PackedStringArray()
	var group_members: Dictionary = {}
	for entry in entries:
		var name := GeneratorUtils.const_name(entry.id)
		var uid := GeneratorUtils.resolve_load_key(entry.path)
		const_lines.append("const %s: StringName = &\"%s\"" % [name, entry.id])
		table_lines.append(
			"\t%s: { \"uid\": \"%s\", \"path\": \"%s\", \"group\": &\"%s\" }," % [
				name, uid, entry.path, entry.group,
			]
		)
		if not group_members.has(entry.group):
			group_members[entry.group] = PackedStringArray()
		(group_members[entry.group] as PackedStringArray).append(name)

	var tail := PackedStringArray([
		"}",
		"",
		"## 分组 → 组内 id 列表(生成期预计算,按组预载/释放遍历用)。",
		"const _GROUPS: Dictionary = {",
	])
	var group_names: Array = group_members.keys()
	group_names.sort_custom(func(a, b) -> bool: return String(a) < String(b))
	for group_name in group_names:
		var members: PackedStringArray = group_members[group_name]
		tail.append("\t&\"%s\": [%s]," % [group_name, ", ".join(members)])
	tail.append_array([
		"}",
		"",
		"static func has_id(id: StringName) -> bool:",
		"\treturn _TABLE.has(id)",
		"",
		"static func ids() -> Array:",
		"\treturn _TABLE.keys()",
		"",
		"static func load_path(id: StringName) -> String:",
		"\tvar entry: Dictionary = _TABLE.get(id, {})",
		"\treturn String(entry.get(\"uid\", \"\"))",
		"",
		"static func file_path(id: StringName) -> String:",
		"\tvar entry: Dictionary = _TABLE.get(id, {})",
		"\treturn String(entry.get(\"path\", \"\"))",
		"",
		"static func group(id: StringName) -> StringName:",
		"\tvar entry: Dictionary = _TABLE.get(id, {})",
		"\treturn StringName(entry.get(\"group\", &\"\"))",
		"",
		"static func ids_in_group(group_name: StringName) -> Array:",
		"\tvar ids_list: Array = _GROUPS.get(group_name, [])",
		"\treturn ids_list",
	])
	return _assemble(
		"Assets",
		"res://src/resource/data/asset_map.tres",
		const_lines,
		PackedStringArray([
			"## id → { uid(加载键), path(仅日志/可读性), group(资产分组) }。",
			"const _TABLE: Dictionary = {",
		]),
		table_lines,
		tail,
	)
#endregion

#region Helpers
static func _sorted_by_id(entries: Array) -> Array:
	var sorted := entries.duplicate()
	sorted.sort_custom(func(a, b) -> bool: return String(a.id) < String(b.id))
	return sorted


static func _assemble(
	class_name_text: String,
	data_path: String,
	const_lines: PackedStringArray,
	table_header: PackedStringArray,
	table_lines: PackedStringArray,
	tail: PackedStringArray,
) -> String:
	var lines := PackedStringArray([
		"class_name %s" % class_name_text,
		"extends RefCounted",
		"",
		"## ⚠ 自动生成,请勿手改 —— 由 Asset Groups 面板(addons/asset_groups) Generate 生成。",
		"## 数据源:%s" % data_path,
		"",
	])
	lines.append_array(const_lines)
	if not const_lines.is_empty():
		lines.append("")
	lines.append_array(table_header)
	lines.append_array(table_lines)
	lines.append_array(tail)
	lines.append("")
	return "\n".join(lines)
#endregion
