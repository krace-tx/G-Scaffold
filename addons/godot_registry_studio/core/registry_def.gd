@tool
class_name RegistryDef
extends RefCounted

## 一种注册表(Scene / UI / Asset)的定义:把三张表的差异集中成数据。
## 供 [RegistryStudio] 的增删改与代码生成、以及 [StudioPanel] 的表驱动 UI 消费。
##
## 每个「额外列」用一个 Dictionary 描述,字段:
## [code]{ key: String, prop: StringName, enum_prefix: String, enum_names: PackedStringArray }[/code]。
## [code]enum_prefix[/code] 为空 → 值渲染成 [code]&"…"[/code] 字面量;
## 非空 → 渲染成 [code]enum_prefix + enum_names[值][/code](int 枚举值 → 符号)。

#region Exports & State
var id: StringName = &""
var display: StringName = &""
var tres: String = ""
var entry_script: String = ""
var resource_field: StringName = &""
var out_path: String = ""
var out_class: StringName = &""
var table_doc: String = ""
var columns: Array[Dictionary] = []
var emits_groups: bool = false
var group_prop: StringName = &""
var groups_doc: String = ""
#endregion

#region Public API
## 当前项目登记的三张注册表定义。
static func all() -> Array[RegistryDef]:
	return [_scene(), _ui(), _asset()]
#endregion

#region Internal
static func _column(
	p_key: String,
	p_prop: StringName,
	p_enum_prefix: String = "",
	p_enum_names: PackedStringArray = PackedStringArray(),
) -> Dictionary:
	return {
		"key": p_key,
		"prop": p_prop,
		"enum_prefix": p_enum_prefix,
		"enum_names": p_enum_names,
	}


static func _scene() -> RegistryDef:
	var d := RegistryDef.new()
	d.id = &"scene"
	d.display = &"Scenes"
	d.tres = PluginConfig.scene_registry_path()
	d.entry_script = PluginConfig.entity_path("entities/scene/scene_registry_entry.gd")
	d.resource_field = &"scene"
	d.out_path = PluginConfig.scene_output_path()
	d.out_class = &"Scenes"
	d.table_doc = "## id → { uid(加载键), path(仅日志/可读性), group(资产分组) }。"
	d.columns = [_column("group", &"asset_group")]
	return d


static func _ui() -> RegistryDef:
	var d := RegistryDef.new()
	d.id = &"ui"
	d.display = &"Uis"
	d.tres = PluginConfig.ui_registry_path()
	d.entry_script = PluginConfig.entity_path("entities/ui/ui_registry_entry.gd")
	d.resource_field = &"scene"
	d.out_path = PluginConfig.ui_output_path()
	d.out_class = &"Uis"
	d.table_doc = "## id → { uid(加载键), path(仅日志/可读性), layer(渲染层), cache(缓存策略) }。"
	d.columns = [
		_column("layer", &"layer", "UIRegistryEntry.Layer.",
			PackedStringArray(["HUD", "WINDOW", "POPUP", "TOAST", "LOADING", "DEBUG"])),
		_column("cache", &"cache", "UIRegistryEntry.Cache.",
			PackedStringArray(["KEEP", "DESTROY"])),
	]
	return d


static func _asset() -> RegistryDef:
	var d := RegistryDef.new()
	d.id = &"asset"
	d.display = &"Assets"
	d.tres = PluginConfig.asset_registry_path()
	d.entry_script = PluginConfig.entity_path("entities/asset/asset_map_entry.gd")
	d.resource_field = &"asset"
	d.out_path = PluginConfig.asset_output_path()
	d.out_class = &"Assets"
	d.table_doc = "## id → { uid(加载键), path(仅日志/可读性), group(资产分组) }。"
	d.columns = [_column("group", &"group")]
	d.emits_groups = true
	d.group_prop = &"group"
	d.groups_doc = "## 分组 → 组内 id 列表(生成期预计算,按组预载/释放遍历用)。"
	return d
#endregion
