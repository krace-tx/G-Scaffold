@tool
class_name RegistryStudio
extends RefCounted

## Registry Studio 引擎:读 .tres(权威源)→ 增删改 / 校验 / 生成常量类 .gd。
##
## 全静态,无状态。[StudioPanel] 与 [plugin.gd] 直接调用。可失败操作返回错误 [String]
## (空串表示成功),读取返回资源或 [code]null[/code]。生成物的骨架见文件底部的模板常量。

#region Constants & Enums
const LOG_PREFIX := "[Registry Studio]"
const ENTRIES := &"entries"
const ID_OVERRIDE := &"id_override"
#endregion

#region Public API — CRUD(供面板)
## 加载定义对应的注册表 .tres;失败返回 [code]null[/code]。
static func load_registry(p_def: RegistryDef) -> Resource:
	if not ResourceLoader.exists(p_def.tres):
		push_error("%s 资源不存在: %s" % [LOG_PREFIX, p_def.tres])
		return null
	return load(p_def.tres)


## 注册表上的全部条目(引用,修改后须 [method save])。
static func entries(p_registry: Resource) -> Array:
	return p_registry.get(ENTRIES)


## 追加一条空白 Entry 并落盘。返回错误 [String](空串=成功)。
static func add_entry(p_def: RegistryDef, p_registry: Resource) -> String:
	var script := load(p_def.entry_script) as GDScript
	if script == null:
		return "条目脚本无效: %s" % p_def.entry_script
	var arr: Array = p_registry.get(ENTRIES)
	arr.append(script.new())
	p_registry.set(ENTRIES, arr)
	return save(p_def, p_registry)


## 按索引删除一条 Entry 并落盘。返回错误 [String](空串=成功)。
static func remove_at(p_def: RegistryDef, p_registry: Resource, p_index: int) -> String:
	var arr: Array = p_registry.get(ENTRIES)
	if p_index < 0 or p_index >= arr.size():
		return "索引越界: %d" % p_index
	arr.remove_at(p_index)
	p_registry.set(ENTRIES, arr)
	return save(p_def, p_registry)


## 将注册表写回 .tres 并刷新编辑器文件系统。返回错误 [String](空串=成功)。
static func save(p_def: RegistryDef, p_registry: Resource) -> String:
	var err := ResourceSaver.save(p_registry, p_def.tres)
	if err != OK:
		return "保存失败(%d): %s" % [err, p_def.tres]
	_refresh(p_def.tres)
	return ""
#endregion

#region Public API — 生成
## 生成全部注册表常量类,任一失败即停。返回错误 [String](空串=成功)。
static func generate_all() -> String:
	for def: RegistryDef in RegistryDef.all():
		var err := generate(def)
		if not err.is_empty():
			return err
	return ""


## 生成单张表并落盘到 [member RegistryDef.out_path]。返回错误 [String](空串=成功)。
static func generate(p_def: RegistryDef) -> String:
	var built := build_content(p_def)
	var err_text: String = built["err"]
	if not err_text.is_empty():
		return err_text
	var write_err := _write_text(p_def.out_path, built["text"])
	if not write_err.is_empty():
		return write_err
	_refresh(p_def.out_path)
	return ""


## 纯函数:算出某张表的 .gd 全文,不落盘(供 diff / 预览)。
## 返回 [code]{ "text": String, "err": String }[/code];err 非空时 text 为空。
static func build_content(p_def: RegistryDef) -> Dictionary:
	var registry := load_registry(p_def)
	if registry == null:
		return {"text": "", "err": "加载失败: %s" % p_def.tres}

	var verr := validate(p_def, registry)
	if not verr.is_empty():
		return {"text": "", "err": verr}

	var rows: Array[Dictionary] = []
	var group_map: Dictionary = {}
	for entry: Resource in registry.get(ENTRIES):
		var resource: Resource = entry.get(p_def.resource_field)
		var row := _to_row(p_def, entry, resource)
		rows.append(row)
		if p_def.emits_groups:
			_accumulate_group(group_map, row["group"], row["const_name"])

	var text := _render(_REGISTRY_TEMPLATE, {
		"CLASS_NAME": String(p_def.out_class),
		"HEADER_DOC": _header_doc(p_def.tres),
		"CONST_DECLARATIONS": _const_declarations(rows),
		"TABLE_DOC": p_def.table_doc,
		"TABLE_ROWS": _table_rows(rows),
		"GROUPS_BLOCK": _groups_block(p_def, group_map),
		"COMMON_ACCESSORS": _COMMON_ACCESSORS,
		"SPECIFIC_ACCESSORS": _accessors_for(p_def.id),
	})
	return {"text": text.strip_edges(false, true) + "\n", "err": ""}
#endregion

#region Public API — 校验 / id
## 解析条目 id:优先 [member id_override],否则取资源文件名。
static func resolve_id(p_entry: Resource, p_resource: Resource) -> StringName:
	var override: StringName = p_entry.get(ID_OVERRIDE)
	if not String(override).is_empty():
		return override
	return StringName(p_resource.resource_path.get_file().get_basename())


## 校验整张表;返回错误 [String](空串=通过,多行=逐条原因)。
static func validate(p_def: RegistryDef, p_registry: Resource) -> String:
	if not p_registry.get(ENTRIES) is Array:
		return "%s: 缺少 entries 数组" % p_def.display

	var errors: Array[String] = []
	var seen_ids: Dictionary = {}
	var arr: Array = p_registry.get(ENTRIES)
	for index: int in arr.size():
		var entry: Resource = arr[index]
		if entry == null:
			errors.append("[%s] 第 %d 条为空" % [p_def.display, index + 1])
			continue
		var resource: Resource = entry.get(p_def.resource_field)
		if resource == null or resource.resource_path.is_empty():
			errors.append("[%s] 第 %d 条未指定资源(%s 为空)" % [p_def.display, index + 1, p_def.resource_field])
			continue
		var id := resolve_id(entry, resource)
		if seen_ids.has(id):
			errors.append("[%s] id 重复: %s(第 %d 条)" % [p_def.display, id, index + 1])
		else:
			seen_ids[id] = true

	return "\n".join(errors)
#endregion

#region Internal — 行装配
static func _to_row(p_def: RegistryDef, p_entry: Resource, p_resource: Resource) -> Dictionary:
	var id := resolve_id(p_entry, p_resource)
	var uid := ResourceUID.id_to_text(ResourceLoader.get_resource_uid(p_resource.resource_path))
	var cols := PackedStringArray()
	for col: Dictionary in p_def.columns:
		cols.append('"%s": %s' % [col["key"], _render_col(col, p_entry.get(col["prop"]))])
	return {
		"const_name": String(id).to_upper(),
		"id": String(id),
		"uid": uid,
		"path": p_resource.resource_path,
		"cols": ", ".join(cols),
		"group": String(p_entry.get(p_def.group_prop)) if p_def.emits_groups else "",
	}


## 把列值渲染成写入生成文件的字面量文本。
static func _render_col(p_col: Dictionary, p_value: Variant) -> String:
	var prefix: String = p_col["enum_prefix"]
	if prefix.is_empty():
		return '&"%s"' % String(p_value)
	var names: PackedStringArray = p_col["enum_names"]
	return prefix + names[int(p_value)]


static func _accumulate_group(p_group_map: Dictionary, p_group: String, p_const_name: String) -> void:
	if not p_group_map.has(p_group):
		p_group_map[p_group] = PackedStringArray()
	p_group_map[p_group].append(p_const_name)
#endregion

#region Internal — 文本渲染
static func _render(p_template: String, p_vars: Dictionary) -> String:
	var out := p_template
	for key: String in p_vars:
		out = out.replace("{{" + key + "}}", String(p_vars[key]))
	return out


static func _header_doc(p_tres: String) -> String:
	return (
		"## ⚠ 自动生成,请勿手改 —— 由「Registry Studio」(%s)生成。\n"
		+ "## 数据源:%s,改动请在面板编辑后重新生成。"
	) % [PluginConfig.plugin_path(), p_tres]


static func _const_declarations(p_rows: Array[Dictionary]) -> String:
	var lines := PackedStringArray()
	for row: Dictionary in p_rows:
		lines.append('const %s: StringName = &"%s"' % [row["const_name"], row["id"]])
	return "\n".join(lines)


static func _table_rows(p_rows: Array[Dictionary]) -> String:
	var lines := PackedStringArray()
	for row: Dictionary in p_rows:
		lines.append('\t%s: { "uid": "%s", "path": "%s", %s },' % [
			row["const_name"], row["uid"], row["path"], row["cols"]
		])
	return "\n".join(lines)


static func _groups_block(p_def: RegistryDef, p_group_map: Dictionary) -> String:
	if not p_def.emits_groups:
		return ""
	var group_rows := PackedStringArray()
	for group_name: String in p_group_map:
		group_rows.append('\t&"%s": [%s],' % [group_name, ", ".join(p_group_map[group_name])])
	return _render(_GROUPS_BLOCK_TEMPLATE, {
		"GROUPS_DOC": p_def.groups_doc,
		"GROUP_ROWS": "\n".join(group_rows),
	})


static func _accessors_for(p_id: StringName) -> String:
	match p_id:
		&"scene":
			return _SCENE_ACCESSORS
		&"ui":
			return _UI_ACCESSORS
		&"asset":
			return _ASSET_ACCESSORS
	return ""
#endregion

#region Internal — 磁盘
static func _write_text(p_path: String, p_content: String) -> String:
	var file := FileAccess.open(p_path, FileAccess.WRITE)
	if file == null:
		return "写入失败(%d): %s" % [FileAccess.get_open_error(), p_path]
	file.store_string(p_content)
	file.close()
	return ""


static func _refresh(p_path: String = "") -> void:
	var filesystem := EditorInterface.get_resource_filesystem()
	if filesystem == null:
		return
	if p_path.is_empty():
		filesystem.scan()
	else:
		filesystem.update_file(p_path)
#endregion

#region Templates(生成物骨架;下方三引号内保持生成代码的 Tab 缩进)
const _REGISTRY_TEMPLATE := """class_name {{CLASS_NAME}}
extends RefCounted

{{HEADER_DOC}}

#region Constants & Enums
{{CONST_DECLARATIONS}}
#endregion

#region State
{{TABLE_DOC}}
const _TABLE: Dictionary = {
{{TABLE_ROWS}}
}
{{GROUPS_BLOCK}}
#endregion

#region Public API
{{COMMON_ACCESSORS}}

{{SPECIFIC_ACCESSORS}}
#endregion"""

const _GROUPS_BLOCK_TEMPLATE := """
{{GROUPS_DOC}}
const _GROUPS: Dictionary = {
{{GROUP_ROWS}}
}"""

const _COMMON_ACCESSORS := """static func has_id(id: StringName) -> bool:
	return _TABLE.has(id)


static func ids() -> Array[StringName]:
	return _TABLE.keys() as Array[StringName]


## ResourceLoader 可用的加载键(uid://);未登记返回空字符串。
static func load_path(id: StringName) -> String:
	if not _TABLE.has(id):
		push_error("[Registry] 致命错误: 试图加载未登记的 ID '%s'" % id)
		return ""
	return _TABLE[id].get("uid", "") as String


## 人类可读的源文件路径(日志用);未登记返回空字符串。
static func file_path(id: StringName) -> String:
	if not _TABLE.has(id):
		return ""
	return _TABLE[id].get("path", "") as String"""

const _SCENE_ACCESSORS := """## 本场景关联的资产分组;未登记或无分组返回 &\"\"。
static func asset_group(id: StringName) -> StringName:
	if not _TABLE.has(id):
		return &""
	return _TABLE[id].get("group", &"") as StringName"""

const _UI_ACCESSORS := """## 界面所属渲染层;未登记返回 WINDOW。
static func layer(id: StringName) -> UIRegistryEntry.Layer:
	if not _TABLE.has(id):
		return UIRegistryEntry.Layer.WINDOW
	return _TABLE[id].get("layer", UIRegistryEntry.Layer.WINDOW) as UIRegistryEntry.Layer


## 界面关闭时的缓存策略;未登记返回 DESTROY。
static func cache(id: StringName) -> UIRegistryEntry.Cache:
	if not _TABLE.has(id):
		return UIRegistryEntry.Cache.DESTROY
	return _TABLE[id].get("cache", UIRegistryEntry.Cache.DESTROY) as UIRegistryEntry.Cache"""

const _ASSET_ACCESSORS := """## 资产所属分组;未登记返回 &\"\"。
static func group(id: StringName) -> StringName:
	if not _TABLE.has(id):
		return &""
	return _TABLE[id].get("group", &"") as StringName


## 某分组内的全部资产 id(生成期预计算);无此分组返回空数组。
static func ids_in_group(group_name: StringName) -> Array[StringName]:
	return _GROUPS.get(group_name, []) as Array[StringName]"""
#endregion
