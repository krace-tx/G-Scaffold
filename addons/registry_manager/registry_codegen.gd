@tool
class_name RegistryCodegen
extends RefCounted

## 读注册表 .tres(权威源)→ 生成 res://src/resource/generated/*.gd 常量类。
##
## [b]编辑器期工具,运行时不用[/b]:生成过程会 load .tres(把资源拉进内存),
## 但产物 [Scenes]/[Uis]/[Assets] 只存 uid 串,运行时查表零加载。
## 表驱动:对 [method RegistryKind.all] 的每个描述符做同一套装配,差异全在描述符里。
## 尾部共有的 has_id/ids/load_path/file_path 四个方法是 schema 级样板,直接内置在
## [constant _COMMON_ACCESSORS];各表特有的访问器在 [member RegistryKind.specific_accessors]。

#region Constants & Enums
## 每张表都一样的四个尾部访问器(逐行,含方法间的两处空行)。
const _COMMON_ACCESSORS: Array[String] = [
	"static func has_id(id: StringName) -> bool:",
	"\treturn _TABLE.has(id)",
	"",
	"",
	"static func ids() -> Array:",
	"\treturn _TABLE.keys()",
	"",
	"",
	"## ResourceLoader 可用的加载键(uid://);未登记返回空字符串。",
	"static func load_path(id: StringName) -> String:",
	"\tvar entry: Dictionary = _TABLE.get(id, {})",
	"\treturn String(entry.get(\"uid\", \"\"))",
	"",
	"",
	"## 人类可读的源文件路径(日志用);未登记返回空字符串。",
	"static func file_path(id: StringName) -> String:",
	"\tvar entry: Dictionary = _TABLE.get(id, {})",
	"\treturn String(entry.get(\"path\", \"\"))",
]
#endregion

#region Public API
## 生成全部注册表常量类,任一失败即停并返回原因。返回 [Result]。
static func generate_all() -> Result:
	for kind in RegistryKind.all():
		var res := generate_kind(kind)
		if res.is_err():
			return res
	return Result.ok()


## 生成单张表并落盘到 [member RegistryKind.out_path]。返回 [Result]。
static func generate_kind(kind: RegistryKind) -> Result:
	var content_res := build_content(kind)
	if content_res.is_err():
		return content_res
	return _write(kind.out_path, content_res.value)


## 纯函数:算出某张表的 .gd 全文文本,不落盘(供 diff / 校验 / 预览)。[br]
## 返回 [Result]:成功时 [member Result.value] 为完整文件字符串;.tres 缺失或某条目
## 未指定资源时失败。
static func build_content(kind: RegistryKind) -> Result:
	var registry: Resource = load(kind.source_tres)
	if registry == null:
		return Result.err("加载注册表失败: %s" % kind.source_tres)

	var rows: Array[Dictionary] = []
	var group_map := {}   # group(String) → Array[String] 常量名,按首次出现排序
	for entry: Resource in registry.entries:
		var res: Resource = entry.get(kind.resource_field)
		if res == null or res.resource_path.is_empty():
			return Result.err("%s 有条目未指定资源(%s 为空)" % [kind.title, kind.resource_field])
		var row := _read_entry(kind, entry, res)
		rows.append(row)
		if kind.emits_groups:
			_accumulate_group(group_map, row["group"], row["const_name"])

	return Result.ok(_assemble(kind, rows, group_map))
#endregion

#region Internal
## 把一条 entry 解析成装配所需的字段包。调用方已保证 [param res] 有效。
static func _read_entry(kind: RegistryKind, entry: Resource, res: Resource) -> Dictionary:
	var id := _resolve_id(entry, res)
	var uid := ResourceUID.id_to_text(ResourceLoader.get_resource_uid(res.resource_path))
	var cols := PackedStringArray()
	for col in kind.columns:
		cols.append('"%s": %s' % [col.key, col.render_value(entry.get(col.prop))])
	return {
		"const_name": String(id).to_upper(),
		"id": String(id),
		"uid": uid,
		"path": res.resource_path,
		"cols": ", ".join(cols),
		"group": String(entry.get(kind.group_prop)) if kind.emits_groups else "",
	}


## id 取 [member id_override],留空则取资源文件名(去扩展名)。
static func _resolve_id(entry: Resource, res: Resource) -> StringName:
	var override: StringName = entry.get(&"id_override")
	if not String(override).is_empty():
		return override
	return StringName(res.resource_path.get_file().get_basename())


static func _accumulate_group(group_map: Dictionary, group_name: String, const_name: String) -> void:
	if not group_map.has(group_name):
		group_map[group_name] = PackedStringArray()
	group_map[group_name].append(const_name)


## 按固定骨架把各部分拼成最终文件文本(以单个换行结尾)。
static func _assemble(kind: RegistryKind, rows: Array[Dictionary], group_map: Dictionary) -> String:
	var lines := PackedStringArray()
	lines.append("class_name " + String(kind.out_class))
	lines.append("extends RefCounted")
	lines.append("")
	for doc in kind.header_doc:
		lines.append(doc)
	lines.append("")
	for row in rows:
		lines.append('const %s: StringName = &"%s"' % [row["const_name"], row["id"]])
	lines.append("")
	lines.append(kind.table_doc)
	lines.append("const _TABLE: Dictionary = {")
	for row in rows:
		lines.append('\t%s: { "uid": "%s", "path": "%s", %s },' % [row["const_name"], row["uid"], row["path"], row["cols"]])
	lines.append("}")
	if kind.emits_groups:
		lines.append("")
		lines.append(kind.groups_doc)
		lines.append("const _GROUPS: Dictionary = {")
		for group_name in group_map:
			lines.append('\t&"%s": [%s],' % [group_name, ", ".join(group_map[group_name])])
		lines.append("}")
	lines.append("")
	lines.append("")
	for line in _COMMON_ACCESSORS:
		lines.append(line)
	lines.append("")
	lines.append("")
	for line in kind.specific_accessors:
		lines.append(line)
	return "\n".join(lines) + "\n"


static func _write(path: String, content: String) -> Result:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return Result.err("写入失败(%d): %s" % [FileAccess.get_open_error(), path])
	f.store_string(content)
	f.close()
	return Result.ok()
#endregion
