@tool
class_name RegistryKind
extends RefCounted

## 一种注册表的「描述符」:把 Scenes/Uis/Assets 三张表的差异全部数据化,
## 让 [RegistryCodegen] 与(后续的)编辑器面板对同一份描述做表驱动处理。
##
## 新增第 4 种注册表 = 在 [method all] 里加一个工厂,无需改生成/面板逻辑。
## 权威数据源仍是 [member source_tres] 指向的 .tres,本类只描述「怎么读、怎么生成」。

#region Exports & State
var title: StringName                    ## 展示名,如 &"Scenes"。
var source_tres: String                  ## 权威数据源 .tres 路径。
var resource_field: StringName           ## entry 上指向资源本体的属性,如 &"scene" / &"asset"。
var out_path: String                     ## 生成的常量类 .gd 输出路径。
var out_class: StringName                ## 生成的类名,如 &"Scenes"。
var header_doc: Array[String] = []       ## 文件顶部两行 ## 说明(逐行)。
var table_doc: String = ""               ## _TABLE 上方的 ## 说明行。
var columns: Array[RegistryColumn] = []  ## _TABLE 每行的额外列(uid/path 之外)。
var emits_groups: bool = false           ## 是否额外生成 _GROUPS(分组 → id 列表)。
var group_prop: StringName = &""         ## emits_groups 时,决定分组归属的 entry 属性。
var groups_doc: String = ""              ## _GROUPS 上方的 ## 说明行。
var specific_accessors: Array[String] = []  ## 本表特有的尾部静态方法(逐行,共有部分见 RegistryCodegen)。
#endregion

#region Public API
## 返回项目当前全部注册表描述符。生成器/面板都以此为唯一枚举入口。
static func all() -> Array[RegistryKind]:
	return [_scenes(), _uis(), _assets()]
#endregion

#region Internal
static func _scenes() -> RegistryKind:
	var k := RegistryKind.new()
	k.title = &"Scenes"
	k.source_tres = "res://src/resource/data/scene_registry.tres"
	k.resource_field = &"scene"
	k.out_path = "res://src/resource/generated/scenes.gd"
	k.out_class = &"Scenes"
	k.header_doc = [
		"## 与 res://src/resource/data/scene_registry.tres 保持同步。",
		"## 增删条目时手改本文件(加载键用 uid://,源文件移动/改名后仍有效)。",
	]
	k.table_doc = "## id → { uid(加载键), path(仅日志/可读性), group(资产分组) }。"
	k.columns = [RegistryColumn.string_name("group", &"asset_group")]
	k.specific_accessors = [
		"## 本场景关联的资产分组;未登记或无分组返回 &\"\"。",
		"static func asset_group(id: StringName) -> StringName:",
		"\tvar entry: Dictionary = _TABLE.get(id, {})",
		"\treturn StringName(entry.get(\"group\", &\"\"))",
	]
	return k


static func _uis() -> RegistryKind:
	var k := RegistryKind.new()
	k.title = &"Uis"
	k.source_tres = "res://src/resource/data/ui_registry.tres"
	k.resource_field = &"scene"
	k.out_path = "res://src/resource/generated/uis.gd"
	k.out_class = &"Uis"
	k.header_doc = [
		"## 与 res://src/resource/data/ui_registry.tres 保持同步。",
		"## 增删条目时手改本文件(加载键用 uid://,源文件移动/改名后仍有效)。",
	]
	k.table_doc = "## id → { uid(加载键), path(仅日志/可读性), layer(渲染层), cache(缓存策略) }。"
	var layer_names := PackedStringArray(["HUD", "WINDOW", "POPUP", "TOAST", "LOADING", "DEBUG"])
	var cache_names := PackedStringArray(["KEEP", "DESTROY"])
	k.columns = [
		RegistryColumn.enum_symbol("layer", &"layer", "UIRegistryEntry.Layer.", layer_names),
		RegistryColumn.enum_symbol("cache", &"cache", "UIRegistryEntry.Cache.", cache_names),
	]
	k.specific_accessors = [
		"## 界面所属渲染层;未登记返回 WINDOW。",
		"static func layer(id: StringName) -> UIRegistryEntry.Layer:",
		"\tvar entry: Dictionary = _TABLE.get(id, {})",
		"\tvar value: int = entry.get(\"layer\", UIRegistryEntry.Layer.WINDOW)",
		"\treturn value as UIRegistryEntry.Layer",
		"",
		"",
		"## 界面关闭时的缓存策略;未登记返回 DESTROY。",
		"static func cache(id: StringName) -> UIRegistryEntry.Cache:",
		"\tvar entry: Dictionary = _TABLE.get(id, {})",
		"\tvar value: int = entry.get(\"cache\", UIRegistryEntry.Cache.DESTROY)",
		"\treturn value as UIRegistryEntry.Cache",
	]
	return k


static func _assets() -> RegistryKind:
	var k := RegistryKind.new()
	k.title = &"Assets"
	k.source_tres = "res://src/resource/data/asset_map.tres"
	k.resource_field = &"asset"
	k.out_path = "res://src/resource/generated/assets.gd"
	k.out_class = &"Assets"
	k.header_doc = [
		"## 与 res://src/resource/data/asset_map.tres 保持同步。",
		"## 增删条目时手改本文件(加载键用 uid://,源文件移动/改名后仍有效)。",
	]
	k.table_doc = "## id → { uid(加载键), path(仅日志/可读性), group(资产分组) }。"
	k.columns = [RegistryColumn.string_name("group", &"group")]
	k.emits_groups = true
	k.group_prop = &"group"
	k.groups_doc = "## 分组 → 组内 id 列表(生成期预计算,按组预载/释放遍历用)。"
	k.specific_accessors = [
		"## 资产所属分组;未登记返回 &\"\"。",
		"static func group(id: StringName) -> StringName:",
		"\tvar entry: Dictionary = _TABLE.get(id, {})",
		"\treturn StringName(entry.get(\"group\", &\"\"))",
		"",
		"",
		"## 某分组内的全部资产 id(生成期预计算);无此分组返回空数组。",
		"static func ids_in_group(group_name: StringName) -> Array:",
		"\tvar ids_list: Array = _GROUPS.get(group_name, [])",
		"\treturn ids_list",
	]
	return k
#endregion
