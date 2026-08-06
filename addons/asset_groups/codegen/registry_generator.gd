@tool
class_name RegistryGenerator
extends RefCounted

## 把 [EditAssetManifest] 编辑态数据转换成运行时三份注册表(RuntimeSceneRegistry/RuntimeUIRegistry/
## RuntimeAssetRegistry)并保存到 [member _SCENE_REGISTRY] 等路径。每次全量重建、整份覆盖——manifest
## 是唯一真源,不对旧文件做增量 merge。

const _SCENE_REGISTRY := "res://src/resource/data/scene_registry.tres"
const _UI_REGISTRY := "res://src/resource/data/ui_registry.tres"
const _ASSET_MAP := "res://src/resource/data/asset_map.tres"
const _RESOURCE_MAP := "res://src/resource/data/resource_map.tres"

#region Public API
## 生成并保存三份注册表,返回 [code]{ errors, written_paths }[/code]。
static func generate_and_save(
	manifest: EditAssetManifest,
	flags: GenerateFlags = null
) -> Dictionary:
	var errors := PackedStringArray()
	var written_paths := PackedStringArray()
	if flags == null:
		flags = GenerateFlags.new()

	if flags.scene_registry:
		var scene_err := _save(_build_scene_registry(manifest), _SCENE_REGISTRY)
		if scene_err != "":
			errors.append(scene_err)
		else:
			written_paths.append(_SCENE_REGISTRY)

	if flags.ui_registry:
		var ui_err := _save(_build_ui_registry(manifest), _UI_REGISTRY)
		if ui_err != "":
			errors.append(ui_err)
		else:
			written_paths.append(_UI_REGISTRY)

	if flags.asset_registry:
		var asset_err := _save(_build_asset_map(manifest), _ASSET_MAP)
		if asset_err != "":
			errors.append(asset_err)
		else:
			written_paths.append(_ASSET_MAP)

	if flags.resource_registry:
		var res_err := _save(_build_resource_map(manifest), _RESOURCE_MAP)
		if res_err != "":
			errors.append(res_err)
		else:
			written_paths.append(_RESOURCE_MAP)

	return {"errors": errors, "written_paths": written_paths}


static func output_paths() -> PackedStringArray:
	return PackedStringArray([_SCENE_REGISTRY, _UI_REGISTRY, _ASSET_MAP, _RESOURCE_MAP])
#endregion

#region Builders
static func _build_scene_registry(manifest: EditAssetManifest) -> RuntimeSceneRegistry:
	var registry := RuntimeSceneRegistry.new()
	for entry in ManifestEntries.complete_scenes(manifest):
		var runtime_entry := RuntimeSceneEntry.new()
		runtime_entry.id = entry.id
		runtime_entry.scene_path = entry.scene_path
		registry.entries.append(runtime_entry)
	return registry


static func _build_ui_registry(manifest: EditAssetManifest) -> RuntimeUIRegistry:
	var registry := RuntimeUIRegistry.new()
	for entry in ManifestEntries.complete_uis(manifest):
		var runtime_entry := RuntimeUIEntry.new()
		runtime_entry.id = entry.id
		runtime_entry.scene_path = entry.scene_path
		# 两边枚举值按序对齐(见 EditUIEntry 文档注释),但静态检查器认两个具名枚举
		# 是不同类型、禁止直接互赋;转一趟 int 绕开这条检查,数值语义不变。
		runtime_entry.layer = int(entry.layer)
		runtime_entry.cache = int(entry.cache)
		registry.entries.append(runtime_entry)
	return registry


static func _build_asset_map(manifest: EditAssetManifest) -> RuntimeAssetRegistry:
	var map := RuntimeAssetRegistry.new()
	for entry in ManifestEntries.complete_assets(manifest):
		var runtime_entry := RuntimeAssetEntry.new()
		runtime_entry.id = entry.id
		runtime_entry.path = entry.path
		runtime_entry.group = entry.group
		map.entries.append(runtime_entry)
	return map


static func _build_resource_map(manifest: EditAssetManifest) -> RuntimeResourceRegistry:
	var map := RuntimeResourceRegistry.new()
	for entry in ManifestEntries.complete_resources(manifest):
		var runtime_entry := RuntimeResourceEntry.new()
		runtime_entry.id = entry.id
		runtime_entry.path = entry.path
		runtime_entry.group = entry.group
		map.entries.append(runtime_entry)
	return map
#endregion

#region Helpers
static func _save(resource: Resource, path: String) -> String:
	var dir_err := AssetGroupsGeneratorUtils.ensure_parent_dir(path)
	if dir_err != "":
		return dir_err
	var err := ResourceSaver.save(resource, path)
	return "" if err == OK else "保存 %s 失败(错误码 %d)" % [path, err]
#endregion
