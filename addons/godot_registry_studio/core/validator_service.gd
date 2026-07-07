@tool
class_name ValidatorService
extends RefCounted

## 注册表数据校验:生成与保存前的统一门禁。

#region Public API
## 校验整张注册表;失败时 [member RegistryResult.error] 为多行原因。返回 [RegistryResult]。
static func validate(p_descriptor: RegistryDescriptor, p_registry: Resource) -> RegistryResult:
	var errors: Array[String] = []
	var seen_ids: Dictionary = {}

	if not p_registry.has_method(&"get") or not p_registry.get(&"entries") is Array:
		return RegistryResult.err("%s: 缺少 entries 数组" % p_descriptor.display_name)

	var entries: Array = p_registry.get(&"entries")
	for index in entries.size():
		var entry: Resource = entries[index]
		if entry == null:
			errors.append("[%s] 第 %d 条为空" % [p_descriptor.display_name, index + 1])
			continue
		var resource_res := EntryUtils.read_resource(p_descriptor, entry)
		if resource_res.is_err():
			errors.append("[%s] 第 %d 条: %s" % [p_descriptor.display_name, index + 1, resource_res.error])
			continue
		var resource: Resource = resource_res.value
		var id := EntryUtils.resolve_id(entry, resource)
		if seen_ids.has(id):
			errors.append("[%s] id 重复: %s (第 %d 条)" % [p_descriptor.display_name, id, index + 1])
		else:
			seen_ids[id] = true

	if errors.is_empty():
		return RegistryResult.ok()
	return RegistryResult.err("\n".join(errors))
#endregion
