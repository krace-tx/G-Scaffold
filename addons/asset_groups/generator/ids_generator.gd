@tool
class_name IdsGenerator
extends RefCounted

## 把清单里的 id 列表整段重写成 SceneIds/UIIds/AssetIds 三个常量类脚本,整份覆盖
## body。生成后的文件请勿手改——下次 Generate 会覆盖,改动一律回到 Dock 操作。

const _SCENE_IDS_PATH := "res://src/resource/scripts/scene_ids.gd"
const _UI_IDS_PATH := "res://src/resource/scripts/ui_ids.gd"
const _ASSET_IDS_PATH := "res://src/resource/scripts/asset_ids.gd"

#region Public API
## 生成并保存三个常量类脚本,返回失败信息(空数组=全部成功)。
static func generate_and_save(manifest: AssetManifest) -> PackedStringArray:
	var errors := PackedStringArray()

	var scene_ids: Array[StringName] = []
	for entry in ManifestEntries.complete_scenes(manifest):
		scene_ids.append(entry.id)
	var scene_err := _write(_SCENE_IDS_PATH, "SceneIds", PackedStringArray([
		"场景 id 常量集中地。代码里一律用 [code]SceneIds.XXX[/code],禁止裸字符串",
		"(见 docs/conventions/naming.md)。id 必须与 scene_registry.tres 里登记的",
		"[member SceneRegistryEntry.id] 完全一致,否则 SceneService 找不到场景。",
	]), scene_ids)
	if scene_err != "":
		errors.append(scene_err)

	var ui_ids: Array[StringName] = []
	for entry in ManifestEntries.complete_uis(manifest):
		ui_ids.append(entry.id)
	var ui_err := _write(_UI_IDS_PATH, "UIIds", PackedStringArray([
		"UI id 常量集中地。代码里一律用 [code]UIIds.XXX[/code],禁止裸字符串",
		"(见 docs/conventions/naming.md)。id 必须与 ui_registry.tres 里登记的",
		"[member UIRegistryEntry.id] 完全一致,否则 UIService 找不到界面。",
	]), ui_ids)
	if ui_err != "":
		errors.append(ui_err)

	var asset_ids: Array[StringName] = []
	for entry in ManifestEntries.complete_assets(manifest):
		asset_ids.append(entry.id)
	var asset_err := _write(_ASSET_IDS_PATH, "AssetIds", PackedStringArray([
		"资产 id 常量集中地。代码一律用 [code]AssetIds.XXX[/code],禁止裸路径",
		"(见 docs/conventions/naming.md)。id 必须与 asset_map.tres 里登记的",
		"[member AssetMapEntry.id] 一致,否则 AssetService 找不到资产。",
	]), asset_ids)
	if asset_err != "":
		errors.append(asset_err)

	return errors
#endregion

#region Helpers
static func _write(path: String, ids_class_name: String, doc_lines: PackedStringArray, ids: Array[StringName]) -> String:
	var sorted_ids := ids.duplicate()
	sorted_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))

	var valid_identifier := RegEx.create_from_string("^[A-Za-z_][A-Za-z0-9_]*$")
	var seen_const_names: Dictionary = {}
	for id in sorted_ids:
		var text := String(id)
		if text.is_empty():
			return "%s: 存在空 id" % ids_class_name
		if not valid_identifier.search(text):
			return "%s: id '%s' 不是合法标识符" % [ids_class_name, text]
		var const_name := text.to_upper()
		if seen_const_names.has(const_name):
			return "%s: id '%s' 与 '%s' 转成常量名后重复(%s)" % [ids_class_name, text, seen_const_names[const_name], const_name]
		seen_const_names[const_name] = text

	var lines := PackedStringArray(["class_name %s" % ids_class_name, "extends RefCounted", ""])
	for doc_line in doc_lines:
		lines.append("## %s" % doc_line)
	lines.append("")
	for id in sorted_ids:
		var text := String(id)
		lines.append("const %s: StringName = &\"%s\"" % [text.to_upper(), text])
	lines.append("")

	var dir_err := GeneratorUtils.ensure_parent_dir(path)
	if dir_err != "":
		return "%s: %s" % [ids_class_name, dir_err]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return "%s: 无法写入 %s(错误码 %d)" % [ids_class_name, path, FileAccess.get_open_error()]
	file.store_string("\n".join(lines))
	file.close()
	return ""
#endregion
