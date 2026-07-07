@tool
class_name CodeGenerator
extends RefCounted

## 读注册表 .tres(权威源)→ 生成常量类 .gd。
##
## 表驱动:对 [method DescriptorFactory.all] 的每个描述符做同一套装配,
## 差异全在描述符与 [code]templates/[/code] 模板文件里。

#region Public API
## 生成全部注册表常量类,任一失败即停。返回 [RegistryResult]。
static func generate_all() -> RegistryResult:
	for descriptor in DescriptorFactory.all():
		var res := generate(descriptor)
		if res.is_err():
			return res
	return RegistryResult.ok()


## 生成单张表并落盘到 [member RegistryDescriptor.output_path]。返回 [RegistryResult]。
static func generate(p_descriptor: RegistryDescriptor) -> RegistryResult:
	var content_res := build_content(p_descriptor)
	if content_res.is_err():
		return content_res
	var write_res := FilesystemService.write_text(p_descriptor.output_path, content_res.value)
	if write_res.is_err():
		return write_res
	FilesystemService.refresh(p_descriptor.output_path)
	return RegistryResult.ok()


## 纯函数:算出某张表的 .gd 全文,不落盘(供 diff / 校验 / 预览)。
static func build_content(p_descriptor: RegistryDescriptor) -> RegistryResult:
	var load_res := FilesystemService.load_resource(p_descriptor.source_tres)
	if load_res.is_err():
		return load_res
	var registry: Resource = load_res.value

	var validate_res := ValidatorService.validate(p_descriptor, registry)
	if validate_res.is_err():
		return validate_res

	var rows: Array[Dictionary] = []
	var group_map := {}
	for entry: Resource in registry.get(&"entries"):
		var resource_res := EntryUtils.read_resource(p_descriptor, entry)
		if resource_res.is_err():
			return resource_res
		var row := EntryUtils.to_row(p_descriptor, entry, resource_res.value)
		rows.append(row)
		if p_descriptor.emits_groups:
			_accumulate_group(group_map, row["group"], row["const_name"])

	var assemble_res := _assemble(p_descriptor, rows, group_map)
	if assemble_res.is_err():
		return assemble_res
	return RegistryResult.ok(assemble_res.value)
#endregion

#region Internal
static func _accumulate_group(p_group_map: Dictionary, p_group_name: String, p_const_name: String) -> void:
	if not p_group_map.has(p_group_name):
		p_group_map[p_group_name] = PackedStringArray()
	p_group_map[p_group_name].append(p_const_name)


static func _assemble(
	p_descriptor: RegistryDescriptor,
	p_rows: Array[Dictionary],
	p_group_map: Dictionary,
) -> RegistryResult:
	var registry_tpl_res := TemplateService.load_text(TemplateService.REGISTRY_TEMPLATE)
	if registry_tpl_res.is_err():
		return registry_tpl_res

	var common_res := TemplateService.load_text(TemplateService.COMMON_ACCESSORS_TEMPLATE)
	if common_res.is_err():
		return common_res

	var specific_res := TemplateService.load_text(p_descriptor.accessors_template)
	if specific_res.is_err():
		return specific_res

	var groups_res := _build_groups_block(p_descriptor, p_group_map)
	if groups_res.is_err():
		return groups_res

	var content := TemplateService.render(registry_tpl_res.value, {
		"CLASS_NAME": String(p_descriptor.output_class),
		"HEADER_DOC": "\n".join(p_descriptor.header_doc),
		"CONST_DECLARATIONS": _build_const_declarations(p_rows),
		"TABLE_DOC": p_descriptor.table_doc,
		"TABLE_ROWS": _build_table_rows(p_rows),
		"GROUPS_BLOCK": groups_res.value,
		"COMMON_ACCESSORS": common_res.value,
		"SPECIFIC_ACCESSORS": specific_res.value,
	})
	return RegistryResult.ok(content.strip_edges(false, true) + "\n")


static func _build_const_declarations(p_rows: Array[Dictionary]) -> String:
	if p_rows.is_empty():
		return ""
	var lines := PackedStringArray()
	for row in p_rows:
		lines.append('const %s: StringName = &"%s"' % [row["const_name"], row["id"]])
	return "\n".join(lines)


static func _build_table_rows(p_rows: Array[Dictionary]) -> String:
	var lines := PackedStringArray()
	for row in p_rows:
		lines.append(
			'\t%s: { "uid": "%s", "path": "%s", %s },' % [row["const_name"], row["uid"], row["path"], row["cols"]]
		)
	return "\n".join(lines)


static func _build_groups_block(
	p_descriptor: RegistryDescriptor,
	p_group_map: Dictionary,
) -> RegistryResult:
	if not p_descriptor.emits_groups:
		return RegistryResult.ok("")

	var block_tpl_res := TemplateService.load_text(TemplateService.GROUPS_BLOCK_TEMPLATE)
	if block_tpl_res.is_err():
		return block_tpl_res

	var group_rows := PackedStringArray()
	for group_name in p_group_map:
		group_rows.append('\t&"%s": [%s],' % [group_name, ", ".join(p_group_map[group_name])])

	return RegistryResult.ok(TemplateService.render(block_tpl_res.value, {
		"GROUPS_DOC": p_descriptor.groups_doc,
		"GROUP_ROWS": "\n".join(group_rows),
	}))
#endregion
