@tool
class_name AssetDescriptor
extends RefCounted

## Asset 注册表描述符工厂。

#region Public API
static func create() -> RegistryDescriptor:
	var descriptor := RegistryDescriptor.new()
	descriptor.id = &"asset"
	descriptor.display_name = &"Assets"
	descriptor.source_tres = PluginConfig.asset_registry_path()
	descriptor.entry_script = PluginConfig.entity_path("entities/asset/asset_map_entry.gd")
	descriptor.resource_field = &"asset"
	descriptor.output_path = PluginConfig.asset_output_path()
	descriptor.output_class = &"Assets"
	descriptor.header_doc = RegistryDescriptor.build_header_doc(descriptor.source_tres)
	descriptor.table_doc = "## id → { uid(加载键), path(仅日志/可读性), group(资产分组) }。"
	descriptor.columns = [RegistryColumn.string_name("group", &"group")]
	descriptor.emits_groups = true
	descriptor.group_prop = &"group"
	descriptor.groups_doc = "## 分组 → 组内 id 列表(生成期预计算,按组预载/释放遍历用)。"
	descriptor.accessors_template = "asset_accessors.tpl"
	return descriptor
#endregion
