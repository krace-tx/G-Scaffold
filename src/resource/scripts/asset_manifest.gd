class_name AssetManifest
extends Resource

## 全项目唯一的资源清单:一份 .tres 同时登记 scene / ui / asset 三类条目,
## 数据实例为 res://src/resource/data/asset_manifest.tres。
##
## 取代了早期分散的 scene_registry / ui_registry / asset_map 三份文件:三个 Service
## (SceneService / UIService / AssetService)都只认这一份清单里登记过的 id,新增
## 内容一律通过编辑器插件(res://addons/asset_groups/)可视化编辑并"导出",导出时
## 会同时刷新本 .tres 与 SceneIds / UIIds / AssetIds 三个常量类,消除手动同步。
##
## 三类条目字段各不相同(UI 有 layer/cache、Scene 有 group、Asset 有 group),故仍按
## 类型分三个数组存放,而不是混装一个数组——查询各走各的 find_*。

#region Exports & State
@export var scenes: Array[SceneEntry] = []
@export var uis: Array[UIEntry] = []
@export var assets: Array[AssetEntry] = []
#endregion

#region Public API
## 查找 [param id] 对应的场景记录,不存在返回 null。
func find_scene(id: StringName) -> SceneEntry:
	for entry in scenes:
		if entry.id == id:
			return entry
	return null


## 查找 [param id] 对应的 UI 记录,不存在返回 null。
func find_ui(id: StringName) -> UIEntry:
	for entry in uis:
		if entry.id == id:
			return entry
	return null


## 查找 [param id] 对应的资产记录,不存在返回 null。
func find_asset(id: StringName) -> AssetEntry:
	for entry in assets:
		if entry.id == id:
			return entry
	return null
#endregion
