@tool
class_name EditAssetManifest
extends Resource

## 编辑态资源清单(唯一真源),持久化为 asset_manifest.tres。
##
## Dock 三页共享同一份实例;Generate 时经 [RegistryGenerator] 整份转换为
## 运行时三份注册表(RuntimeSceneRegistry / RuntimeUIRegistry / RuntimeAssetRegistry)并落盘。

#region Exports & State
## 登记的顶层场景列表。决定了场景 ID、路径以及切场景时的资产预载关联。
@export var scenes: Array[EditSceneEntry] = []

## 登记的 UI 界面列表。记录了 UI ID、路径、挂载层级与缓存策略。
@export var uis: Array[EditUIEntry] = []

## 登记的通用资产列表。记录了资源 ID、路径及其所属的内存生命周期分组。
@export var assets: Array[EditAssetEntry] = []

## 登记的资源列表。记录了资源 ID、路径及其所属的内存生命周期分组。
@export var resources: Array[EditResourceEntry] = []

## 显式登记的分组名(含空组);资产引用的组名也会出现在 [method collect_asset_groups] 中。
@export var groups: Array[StringName] = []

## 显式登记的资源分组名(含空组);资源引用的组名也会出现在 [method collect_resource_groups] 中。
@export var resource_groups: Array[StringName] = []
#endregion

#region Public API
## 根据 [param id] 查找并返回对应的场景条目。未找到则返回 null。
func find_scene(id: StringName) -> EditSceneEntry:
	for entry in scenes:
		if entry.id == id:
			return entry
	return null

## 根据 [param id] 查找并返回对应的 UI 条目。未找到则返回 null。
func find_ui(id: StringName) -> EditUIEntry:
	for entry in uis:
		if entry.id == id:
			return entry
	return null

## 根据 [param id] 查找并返回对应的资产条目。未找到则返回 null。
func find_asset(id: StringName) -> EditAssetEntry:
	for entry in assets:
		if entry.id == id:
			return entry
	return null

## 根据 [param id] 查找并返回对应的资源条目。未找到则返回 null。
func find_resource(id: StringName) -> EditResourceEntry:
	for entry in resources:
		if entry.id == id:
			return entry
	return null

## 筛选并返回归属于指定分组 [param group_name] 的所有资源条目。
func resources_in_group(group_name: StringName) -> Array[EditResourceEntry]:
	var result: Array[EditResourceEntry] = []
	for entry in resources:
		if entry.group == group_name:
			result.append(entry)
	return result

## 筛选并返回归属于指定分组 [param group_name] 的所有资产条目。
func assets_in_group(group_name: StringName) -> Array[EditAssetEntry]:
	var result: Array[EditAssetEntry] = []
	for entry in assets:
		if entry.group == group_name:
			result.append(entry)
	return result

## 聚合查询资产组：合并 [member groups] 与资产条目中实际引用的组名并去重。
func collect_asset_groups() -> PackedStringArray:
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

## 聚合查询资源组：合并 [member resource_groups] 与资源条目中实际引用的组名并去重。
func collect_resource_groups() -> PackedStringArray:
	var seen: Dictionary = {}
	var result: PackedStringArray = []
	for group_name in resource_groups:
		if group_name != &"" and not seen.has(group_name):
			seen[group_name] = true
			result.append(String(group_name))
	for entry in resources:
		if entry.group != &"" and not seen.has(entry.group):
			seen[entry.group] = true
			result.append(String(entry.group))
	result.sort()
	return result

## 显式新增一个资产分组。
func add_asset_group(group_name: StringName) -> void:
	if group_name == &"" or groups.has(group_name):
		return
	groups.append(group_name)

## 显式新增一个资源分组。
func add_resource_group(group_name: StringName) -> void:
	if group_name == &"" or resource_groups.has(group_name):
		return
	resource_groups.append(group_name)

## 移除资产分组。
func remove_asset_group(group_name: StringName) -> void:
	if group_name == &"":
		return
	groups.erase(group_name)
	for entry in assets:
		if entry.group == group_name:
			entry.group = &""

## 移除资源分组。
func remove_resource_group(group_name: StringName) -> void:
	if group_name == &"":
		return
	resource_groups.erase(group_name)
	for entry in resources:
		if entry.group == group_name:
			entry.group = &""

## 重命名资产分组。
func rename_asset_group(old_name: StringName, new_name: StringName) -> void:
	if old_name == new_name or String(new_name).is_empty():
		return
	var idx := groups.find(old_name)
	if idx >= 0:
		groups[idx] = new_name
	else:
		add_asset_group(new_name)
	for entry in assets:
		if entry.group == old_name:
			entry.group = new_name

## 重命名资源分组。
func rename_resource_group(old_name: StringName, new_name: StringName) -> void:
	if old_name == new_name or String(new_name).is_empty():
		return
	var idx := resource_groups.find(old_name)
	if idx >= 0:
		resource_groups[idx] = new_name
	else:
		add_resource_group(new_name)
	for entry in resources:
		if entry.group == old_name:
			entry.group = new_name
#endregion
