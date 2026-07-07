@tool
class_name AssetManifest
extends Resource

## 编辑态资源清单(唯一真源),持久化为 asset_manifest.tres。
##
## Dock 三页共享同一份实例;Generate 时经 [RegistryGenerator] 整份转换为
## 运行时三份注册表(SceneRegistry / UIRegistry / AssetMap)并落盘。

#region Exports & State
@export var scenes: Array[SceneEntry] = []
@export var uis: Array[UIEntry] = []
@export var assets: Array[AssetEntry] = []
## 显式登记的分组名(含空组);资产/场景引用的组名也会出现在 [method collect_groups] 中。
@export var groups: Array[StringName] = [&"core"]
#endregion

#region Public API
func find_scene(id: StringName) -> SceneEntry:
	for entry in scenes:
		if entry.id == id:
			return entry
	return null


func find_ui(id: StringName) -> UIEntry:
	for entry in uis:
		if entry.id == id:
			return entry
	return null


func find_asset(id: StringName) -> AssetEntry:
	for entry in assets:
		if entry.id == id:
			return entry
	return null


func assets_in_group(group_name: StringName) -> Array[AssetEntry]:
	var result: Array[AssetEntry] = []
	for entry in assets:
		if entry.group == group_name:
			result.append(entry)
	return result


## 合并显式 [member groups] 与资产条目引用的组名,按字母序返回。
func collect_groups() -> PackedStringArray:
	var seen: Dictionary = {}
	var result: PackedStringArray = []
	for group_name in groups:
		if group_name != &"" and not seen.has(group_name):
			seen[group_name] = true
			result.append(String(group_name))
	for entry in assets:
		if entry.group != &"" and not seen.has(entry.group):
			seen[entry.group] = true
			result.append(String(entry.group))
	result.sort()
	return result


func add_group(group_name: StringName) -> void:
	if group_name == &"" or groups.has(group_name):
		return
	groups.append(group_name)


func remove_group(group_name: StringName) -> void:
	if group_name == &"" or group_name == &"core":
		return
	groups.erase(group_name)
	for entry in assets:
		if entry.group == group_name:
			entry.group = &"core"
	for entry in scenes:
		if entry.asset_group == group_name:
			entry.asset_group = &""


func rename_group(old_name: StringName, new_name: StringName) -> void:
	if old_name == new_name or String(new_name).is_empty():
		return
	var idx := groups.find(old_name)
	if idx >= 0:
		groups[idx] = new_name
	else:
		add_group(new_name)
	for entry in assets:
		if entry.group == old_name:
			entry.group = new_name
	for entry in scenes:
		if entry.asset_group == old_name:
			entry.asset_group = new_name
#endregion
