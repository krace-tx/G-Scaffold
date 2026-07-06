@tool
class_name RegistryColumn
extends RefCounted

## 描述注册表 [code]_TABLE[/code] 里一条目的一个「额外列」如何取值与渲染。
## 例如 Scenes 的 group 列、Uis 的 layer/cache 列。由 [RegistryKind] 组合、
## [RegistryCodegen] 消费,是「表驱动生成」把三张表差异数据化的最小单元。

#region Constants & Enums
## 值的渲染方式:StringName 字面量([code]&"x"[/code])或枚举符号([code]Enum.NAME[/code])。
enum Render { STRINGNAME, ENUM }
#endregion

#region Exports & State
var key: String                      ## _TABLE 行里的字典键,如 "group" / "layer"。
var prop: StringName                 ## 从 entry 上读取的属性名,如 &"asset_group"。
var render: Render = Render.STRINGNAME
var enum_prefix: String = ""         ## ENUM 模式下的限定前缀,如 "UIRegistryEntry.Layer."。
var enum_names: PackedStringArray = PackedStringArray()  ## ENUM 模式下按序号索引的符号名。
#endregion

#region Public API
## 构造一个渲染成 StringName 字面量的列（[param p_prop] 的值会包成 [code]&"…"[/code]）。
static func string_name(p_key: String, p_prop: StringName) -> RegistryColumn:
	var col := RegistryColumn.new()
	col.key = p_key
	col.prop = p_prop
	col.render = Render.STRINGNAME
	return col


## 构造一个渲染成枚举符号的列（int 值 → [code]p_prefix + p_names[值][/code]）。
static func enum_symbol(p_key: String, p_prop: StringName, p_prefix: String, p_names: PackedStringArray) -> RegistryColumn:
	var col := RegistryColumn.new()
	col.key = p_key
	col.prop = p_prop
	col.render = Render.ENUM
	col.enum_prefix = p_prefix
	col.enum_names = p_names
	return col


## 把 entry 上读到的 [param value] 渲染成写进生成文件的字面量文本。
func render_value(value: Variant) -> String:
	if render == Render.ENUM:
		return enum_prefix + enum_names[int(value)]
	return '&"%s"' % String(value)
#endregion
