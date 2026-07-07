@tool
class_name RegistryService
extends RefCounted

## 注册表 CRUD 与代码生成的统一门面;UI 只通过本类访问数据。

#region Constants & Enums
const ENTRIES_PROP := &"entries"
#endregion

#region Public API
## 加载 [param p_descriptor] 对应的注册表 .tres。返回 [RegistryResult]。
func load_registry(p_descriptor: RegistryDescriptor) -> RegistryResult:
	return FilesystemService.load_resource(p_descriptor.source_tres)


## 返回注册表上的全部条目(只读引用,修改后须 [method save_registry])。
func get_entries(p_registry: Resource) -> Array:
	return p_registry.get(ENTRIES_PROP)


## 创建一条空白 Entry 实例。返回 [RegistryResult]。
func create_entry(p_descriptor: RegistryDescriptor) -> RegistryResult:
	var script := load(p_descriptor.entry_script) as GDScript
	if script == null:
		return RegistryResult.err("条目脚本无效: %s" % p_descriptor.entry_script)
	return RegistryResult.ok(script.new())


## 向注册表追加一条 Entry。
func add_entry(p_registry: Resource, p_entry: Resource) -> RegistryResult:
	var entries: Array = p_registry.get(ENTRIES_PROP)
	entries.append(p_entry)
	p_registry.set(ENTRIES_PROP, entries)
	return RegistryResult.ok()


## 按索引删除一条 Entry。
func remove_entry_at(p_registry: Resource, p_index: int) -> RegistryResult:
	var entries: Array = p_registry.get(ENTRIES_PROP)
	if p_index < 0 or p_index >= entries.size():
		return RegistryResult.err("索引越界: %d" % p_index)
	entries.remove_at(p_index)
	p_registry.set(ENTRIES_PROP, entries)
	return RegistryResult.ok()


## 将注册表写回 .tres 并刷新编辑器文件系统。[param p_validate] 为 true 时先校验。
func save_registry(
	p_descriptor: RegistryDescriptor,
	p_registry: Resource,
	p_validate: bool = false,
) -> RegistryResult:
	if p_validate:
		var validate_res := ValidatorService.validate(p_descriptor, p_registry)
		if validate_res.is_err():
			return validate_res
	var save_res := FilesystemService.save_resource(p_descriptor.source_tres, p_registry)
	if save_res.is_err():
		return save_res
	FilesystemService.refresh(p_descriptor.source_tres)
	return RegistryResult.ok()


## 生成单张表的常量类。返回 [RegistryResult]。
func generate(p_descriptor: RegistryDescriptor) -> RegistryResult:
	return CodeGenerator.generate(p_descriptor)


## 生成全部注册表常量类,任一失败即停。返回 [RegistryResult]。
func generate_all() -> RegistryResult:
	return CodeGenerator.generate_all()
#endregion
