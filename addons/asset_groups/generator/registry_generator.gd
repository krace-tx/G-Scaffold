@tool
class_name RegistryGenerator
extends RefCounted

## 把 [AssetManifest] 编辑态数据转换成运行时三份注册表(SceneRegistry/UIRegistry/
## AssetMap)并保存到 [member _SCENE_REGISTRY] 等路径。每次全量重建、整份覆盖——manifest
## 是唯一真源,不对旧文件做增量 merge。

const _SCENE_REGISTRY := "res://src/resource/data/scene_registry.tres"
const _UI_REGISTRY := "res://src/resource/data/ui_registry.tres"
const _ASSET_MAP := "res://src/resource/data/asset_map.tres"

#region Public API
## 生成并保存三份注册表,返回保存失败的错误信息(空数组=全部成功)。
static func generate_and_save(manifest: AssetManifest) -> PackedStringArray:
	var errors := PackedStringArray()

	var scene_err := _save(_build_scene_registry(manifest), _SCENE_REGISTRY)
	if scene_err != "":
		errors.append(scene_err)

	var ui_err := _save(_build_ui_registry(manifest), _UI_REGISTRY)
	if ui_err != "":
		errors.append(ui_err)

	var asset_err := _save(_build_asset_map(manifest), _ASSET_MAP)
	if asset_err != "":
		errors.append(asset_err)

	return errors
#endregion

#region Builders
static func _build_scene_registry(manifest: AssetManifest) -> SceneRegistry:
	var registry := SceneRegistry.new()
	for entry in ManifestEntries.complete_scenes(manifest):
		var runtime_entry := SceneRegistryEntry.new()
		runtime_entry.id = entry.id
		runtime_entry.scene_path = entry.scene_path
		runtime_entry.asset_group = entry.asset_group
		registry.entries.append(runtime_entry)
	return registry


static func _build_ui_registry(manifest: AssetManifest) -> UIRegistry:
	var registry := UIRegistry.new()
	for entry in ManifestEntries.complete_uis(manifest):
		var runtime_entry := UIRegistryEntry.new()
		runtime_entry.id = entry.id
		runtime_entry.scene_path = entry.scene_path
		# 两边枚举值按序对齐(见 UIEntry 文档注释),但静态检查器认两个具名枚举
		# 是不同类型、禁止直接互赋;转一趟 int 绕开这条检查,数值语义不变。
		runtime_entry.layer = int(entry.layer)
		runtime_entry.cache = int(entry.cache)
		registry.entries.append(runtime_entry)
	return registry


static func _build_asset_map(manifest: AssetManifest) -> AssetMap:
	var map := AssetMap.new()
	for entry in ManifestEntries.complete_assets(manifest):
		var runtime_entry := AssetMapEntry.new()
		runtime_entry.id = entry.id
		runtime_entry.path = entry.path
		runtime_entry.group = entry.group
		map.entries.append(runtime_entry)
	return map
#endregion

#region Helpers
static func _save(resource: Resource, path: String) -> String:
	var dir_err := GeneratorUtils.ensure_parent_dir(path)
	if dir_err != "":
		return dir_err
	var err := ResourceSaver.save(resource, path)
	return "" if err == OK else "保存 %s 失败(错误码 %d)" % [path, err]
#endregion
