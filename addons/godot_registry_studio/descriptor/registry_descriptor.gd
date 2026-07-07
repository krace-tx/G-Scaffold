@tool
class_name RegistryDescriptor
extends RefCounted

## 一种注册表的描述符:把 Scene/UI/Asset 的差异数据化,
## 供 [CodeGenerator]、[RegistryService] 与 UI 表驱动处理。

#region Exports & State
var id: StringName = &""
var display_name: StringName = &""
var source_tres: String = ""
var entry_script: String = ""
var resource_field: StringName = &""
var output_path: String = ""
var output_class: StringName = &""
var header_doc: Array[String] = []
var table_doc: String = ""
var columns: Array[RegistryColumn] = []
var emits_groups: bool = false
var group_prop: StringName = &""
var groups_doc: String = ""
var accessors_template: String = ""
#endregion

#region Public API
## 生成文件顶部的自动文档注释行。
static func build_header_doc(p_source_tres: String) -> Array[String]:
	var plugin_path := PluginConfig.plugin_path()
	return [
		"## ⚠ 自动生成,请勿手改 —— 由「Registry Studio」(%s)生成。" % plugin_path,
		"## 数据源:%s,改动请在面板编辑后重新生成。" % p_source_tres,
	]
#endregion
