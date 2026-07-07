@tool
class_name SceneDescriptor
extends RefCounted

## Scene 注册表描述符工厂。

#region Public API
static func create() -> RegistryDescriptor:
	var descriptor := RegistryDescriptor.new()
	descriptor.id = &"scene"
	descriptor.display_name = &"Scenes"
	descriptor.source_tres = PluginConfig.scene_registry_path()
	descriptor.entry_script = PluginConfig.entity_path("entities/scene/scene_registry_entry.gd")
	descriptor.resource_field = &"scene"
	descriptor.output_path = PluginConfig.scene_output_path()
	descriptor.output_class = &"Scenes"
	descriptor.header_doc = RegistryDescriptor.build_header_doc(descriptor.source_tres)
	descriptor.table_doc = "## id → { uid(加载键), path(仅日志/可读性), group(资产分组) }。"
	descriptor.columns = [RegistryColumn.string_name("group", &"asset_group")]
	descriptor.accessors_template = "scene_accessors.tpl"
	return descriptor
#endregion
