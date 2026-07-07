@tool
class_name DescriptorFactory
extends RefCounted

## 注册表描述符的注册中心;新增 Registry 类型只需增加 Descriptor 工厂。

#region Public API
## 返回当前项目已注册的全部描述符。
static func all() -> Array[RegistryDescriptor]:
	return [
		SceneDescriptor.create(),
		UIDescriptor.create(),
		AssetDescriptor.create(),
	]


## 按 [param p_id] 查找描述符,未找到返回 [code]null[/code]。
static func by_id(p_id: StringName) -> RegistryDescriptor:
	for descriptor in all():
		if descriptor.id == p_id:
			return descriptor
	return null
#endregion
