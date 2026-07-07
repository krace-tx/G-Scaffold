@tool
class_name EntryUtils
extends RefCounted

## 注册表条目的 id 解析与行数据提取,供校验与代码生成共用。

#region Public API
## 解析条目 id:优先 [member id_override],否则取资源文件名。
static func resolve_id(p_entry: Resource, p_resource: Resource) -> StringName:
	var override: StringName = p_entry.get(&"id_override")
	if not String(override).is_empty():
		return override
	return StringName(p_resource.resource_path.get_file().get_basename())


## 读取条目上的资源引用;未指定时返回失败 [RegistryResult]。
static func read_resource(
	p_descriptor: RegistryDescriptor,
	p_entry: Resource,
) -> RegistryResult:
	var resource: Resource = p_entry.get(p_descriptor.resource_field)
	if resource == null or resource.resource_path.is_empty():
		return RegistryResult.err(
			"有条目未指定资源(%s 为空)" % p_descriptor.resource_field
		)
	return RegistryResult.ok(resource)


## 将一条 entry 解析成代码生成所需的字段包。
static func to_row(
	p_descriptor: RegistryDescriptor,
	p_entry: Resource,
	p_resource: Resource,
) -> Dictionary:
	var id := resolve_id(p_entry, p_resource)
	var uid := ResourceUID.id_to_text(ResourceLoader.get_resource_uid(p_resource.resource_path))
	var cols := PackedStringArray()
	for col in p_descriptor.columns:
		cols.append('"%s": %s' % [col.key, col.render_value(p_entry.get(col.prop))])
	return {
		"const_name": String(id).to_upper(),
		"id": String(id),
		"uid": uid,
		"path": p_resource.resource_path,
		"cols": ", ".join(cols),
		"group": String(p_entry.get(p_descriptor.group_prop)) if p_descriptor.emits_groups else "",
	}
#endregion
