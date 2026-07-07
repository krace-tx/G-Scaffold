@tool
class_name RegistryColumn
extends RefCounted

## 描述注册表 [code]_TABLE[/code] 里一条目的一个「额外列」如何取值与渲染。
## 由 [RegistryDescriptor] 组合、[CodeGenerator] 消费。

#region Constants & Enums
enum Render { STRINGNAME, ENUM }
#endregion

#region Exports & State
var key: String = ""
var prop: StringName = &""
var render: Render = Render.STRINGNAME
var enum_prefix: String = ""
var enum_names: PackedStringArray = PackedStringArray()
#endregion

#region Public API
## 构造渲染成 StringName 字面量的列。
static func string_name(p_key: String, p_prop: StringName) -> RegistryColumn:
	var col := RegistryColumn.new()
	col.key = p_key
	col.prop = p_prop
	col.render = Render.STRINGNAME
	return col


## 构造渲染成枚举符号的列(int 值 → [code]p_prefix + p_names[值][/code])。
static func enum_symbol(
	p_key: String,
	p_prop: StringName,
	p_prefix: String,
	p_names: PackedStringArray,
) -> RegistryColumn:
	var col := RegistryColumn.new()
	col.key = p_key
	col.prop = p_prop
	col.render = Render.ENUM
	col.enum_prefix = p_prefix
	col.enum_names = p_names
	return col


## 把 entry 属性值渲染成写入生成文件的字面量文本。
func render_value(p_value: Variant) -> String:
	if render == Render.ENUM:
		return enum_prefix + enum_names[int(p_value)]
	return '&"%s"' % String(p_value)
#endregion
