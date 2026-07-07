@tool
class_name UIDescriptor
extends RefCounted

## UI 注册表描述符工厂。

#region Public API
static func create() -> RegistryDescriptor:
	var descriptor := RegistryDescriptor.new()
	descriptor.id = &"ui"
	descriptor.display_name = &"Uis"
	descriptor.source_tres = PluginConfig.ui_registry_path()
	descriptor.entry_script = PluginConfig.entity_path("entities/ui/ui_registry_entry.gd")
	descriptor.resource_field = &"scene"
	descriptor.output_path = PluginConfig.ui_output_path()
	descriptor.output_class = &"Uis"
	descriptor.header_doc = RegistryDescriptor.build_header_doc(descriptor.source_tres)
	descriptor.table_doc = "## id → { uid(加载键), path(仅日志/可读性), layer(渲染层), cache(缓存策略) }。"
	var layer_names := PackedStringArray(["HUD", "WINDOW", "POPUP", "TOAST", "LOADING", "DEBUG"])
	var cache_names := PackedStringArray(["KEEP", "DESTROY"])
	descriptor.columns = [
		RegistryColumn.enum_symbol("layer", &"layer", "UIRegistryEntry.Layer.", layer_names),
		RegistryColumn.enum_symbol("cache", &"cache", "UIRegistryEntry.Cache.", cache_names),
	]
	descriptor.accessors_template = "ui_accessors.tpl"
	return descriptor
#endregion
