extends RefCounted

## 注册表代码生成核心:读 src/resource/data/ 下的三份权威 .tres,生成
## src/resource/generated/ 下的强类型常量类(Scenes / Uis / Assets)。
##
## 无 class_name——入口用 preload 按路径引用,不依赖全局类注册。两个入口:
##   - 编辑器一键:File > Run 运行 res://tools/editor_regen_registries.gd
##   - 无头/CI:godot --headless --path . res://tools/generate_registries.tscn
##     (追加 `-- check` 只校验不写盘,生成物过期/出错时退出码非 0)
##
## id 规则:默认取资源文件名(main_menu.tscn → &"main_menu"),条目 id_override
## 非空时覆盖;id 必须是合法 snake_case 标识符且同表内唯一,违反即报错拒绝生成。
## 加载键用 uid://(抗移动/改名),path 一并写入仅供日志与可读性。

const _SCENE_SOURCE := "res://src/resource/data/scene_registry.tres"
const _UI_SOURCE := "res://src/resource/data/ui_registry.tres"
const _ASSET_SOURCE := "res://src/resource/data/asset_map.tres"
const _OUT_DIR := "res://src/resource/generated"

const _COMMON_FUNCS := """

static func has_id(id: StringName) -> bool:
	return _TABLE.has(id)


static func ids() -> Array:
	return _TABLE.keys()


## ResourceLoader 可用的加载键(uid://);未登记返回空字符串。
static func load_path(id: StringName) -> String:
	var entry: Dictionary = _TABLE.get(id, {})
	return String(entry.get("uid", ""))


## 人类可读的源文件路径(日志用);未登记返回空字符串。
static func file_path(id: StringName) -> String:
	var entry: Dictionary = _TABLE.get(id, {})
	return String(entry.get("path", ""))
"""

const _SCENE_FUNCS := """

## 本场景关联的资产分组;未登记或无分组返回 &""。
static func asset_group(id: StringName) -> StringName:
	var entry: Dictionary = _TABLE.get(id, {})
	return StringName(entry.get("group", &""))
"""

const _UI_FUNCS := """

## 界面所属渲染层;未登记返回 WINDOW。
static func layer(id: StringName) -> UIRegistryEntry.Layer:
	var entry: Dictionary = _TABLE.get(id, {})
	var value: int = entry.get("layer", UIRegistryEntry.Layer.WINDOW)
	return value as UIRegistryEntry.Layer


## 界面关闭时的缓存策略;未登记返回 DESTROY。
static func cache(id: StringName) -> UIRegistryEntry.Cache:
	var entry: Dictionary = _TABLE.get(id, {})
	var value: int = entry.get("cache", UIRegistryEntry.Cache.DESTROY)
	return value as UIRegistryEntry.Cache
"""

const _ASSET_FUNCS := """

## 资产所属分组;未登记返回 &""。
static func group(id: StringName) -> StringName:
	var entry: Dictionary = _TABLE.get(id, {})
	return StringName(entry.get("group", &""))


## 某分组内的全部资产 id(生成期预计算);无此分组返回空数组。
static func ids_in_group(group_name: StringName) -> Array:
	var ids_list: Array = _GROUPS.get(group_name, [])
	return ids_list
"""


## 全量生成/校验。返回 {"written", "stale", "up_to_date", "errors"} 四个数组。
## check_only 时不写盘,内容有出入的文件进 "stale"。
static func run(check_only: bool) -> Dictionary:
	var result: Dictionary = {"written": [], "stale": [], "up_to_date": [], "errors": []}
	var scenes: Dictionary = _scan(_SCENE_SOURCE, "scene")
	var uis: Dictionary = _scan(_UI_SOURCE, "scene")
	var assets: Dictionary = _scan(_ASSET_SOURCE, "asset")
	var errors: Array = result["errors"]
	errors.append_array(scenes["errors"])
	errors.append_array(uis["errors"])
	errors.append_array(assets["errors"])
	if not errors.is_empty():
		return result

	_cross_check_groups(scenes["rows"], assets["rows"])
	DirAccess.make_dir_recursive_absolute(_OUT_DIR)
	_apply(_OUT_DIR + "/scenes.gd", _emit_scenes(scenes["rows"]), check_only, result)
	_apply(_OUT_DIR + "/uis.gd", _emit_uis(uis["rows"]), check_only, result)
	_apply(_OUT_DIR + "/assets.gd", _emit_assets(assets["rows"]), check_only, result)
	return result


## 读一份注册表,产出行数据 [{id, const_name, uid, path, entry}]。
## [param res_prop] 是条目上资源引用字段的名字("scene" / "asset")。
static func _scan(source_path: String, res_prop: String) -> Dictionary:
	var rows: Array[Dictionary] = []
	var errors: Array[String] = []
	var registry: Resource = load(source_path)
	if registry == null:
		errors.append("无法加载注册表:%s" % source_path)
		return {"rows": rows, "errors": errors}

	var entries: Array = registry.get("entries")
	var seen: Dictionary = {}
	for i: int in entries.size():
		var entry: Resource = entries[i]
		var res: Resource = entry.get(res_prop) if entry != null else null
		if res == null or res.resource_path.is_empty():
			errors.append("%s 第 %d 条:%s 为空(没拖资源进去?)" % [source_path, i + 1, res_prop])
			continue
		var path: String = res.resource_path
		var id: StringName = entry.get("id_override")
		if id == &"":
			id = StringName(path.get_file().get_basename())
		if not _is_valid_id(String(id)):
			errors.append("%s 第 %d 条:id '%s' 不是合法 snake_case 标识符" % [source_path, i + 1, id])
			continue
		if seen.has(id):
			errors.append("%s 第 %d 条:id '%s' 重复(同名文件用 id_override 区分)" % [source_path, i + 1, id])
			continue
		seen[id] = true
		var uid_int: int = ResourceLoader.get_resource_uid(path)
		var uid_text: String = path if uid_int == ResourceUID.INVALID_ID else ResourceUID.id_to_text(uid_int)
		rows.append({"id": id, "const_name": String(id).to_upper(), "uid": uid_text, "path": path, "entry": entry})
	return {"rows": rows, "errors": errors}


## id 必须是 snake_case 标识符(小写字母开头,只含小写字母/数字/下划线),
## 否则大写后不是合法的 GDScript 常量名。
static func _is_valid_id(id: String) -> bool:
	if id.is_empty():
		return false
	for i: int in id.length():
		var c: String = id[i]
		var lower: bool = c >= "a" and c <= "z"
		var digit: bool = c >= "0" and c <= "9"
		if i == 0 and not lower:
			return false
		if not (lower or digit or c == "_"):
			return false
	return true


## 场景声明的 asset_group 应当在 asset_map 里真的有资产,否则大概率是拼写错误。
## 只警告不拒绝生成:空分组本来就是合法的"不走分组预载"路径。
static func _cross_check_groups(scene_rows: Array, asset_rows: Array) -> void:
	var known: Dictionary = {}
	for row: Dictionary in asset_rows:
		var entry: Resource = row["entry"]
		known[entry.get("group")] = true
	for row: Dictionary in scene_rows:
		var entry: Resource = row["entry"]
		var group_name: StringName = entry.get("asset_group")
		if group_name != &"" and not known.has(group_name):
			push_warning("场景 '%s' 的 asset_group '%s' 在 asset_map 里没有任何资产" % [row["id"], group_name])


## 写盘。内容没变不动文件(避免无谓的重导入);check_only 时只比对不写。
static func _apply(out_path: String, text: String, check_only: bool, result: Dictionary) -> void:
	var current: String = FileAccess.get_file_as_string(out_path)
	if current == text:
		(result["up_to_date"] as Array).append(out_path)
		return
	if check_only:
		(result["stale"] as Array).append(out_path)
		return
	var file: FileAccess = FileAccess.open(out_path, FileAccess.WRITE)
	if file == null:
		(result["errors"] as Array).append("无法写入 %s" % out_path)
		return
	file.store_string(text)
	file.close()
	(result["written"] as Array).append(out_path)


static func _header(cls: String, source: String) -> String:
	return (
		"class_name %s\n" % cls
		+ "extends RefCounted\n"
		+ "\n"
		+ "## GENERATED — 本文件由 tools/registry_codegen.gd 生成,手改会在下次生成时丢失。\n"
		+ "## 数据源:%s(Inspector 里拖资源进条目即完成登记)。\n" % source
		+ "## 重新生成:编辑器 File > Run 跑 res://tools/editor_regen_registries.gd,或命令行\n"
		+ "## godot --headless --path . res://tools/generate_registries.tscn(加 `-- check` 只校验)。\n"
		+ "##\n"
		+ "## 加载键是 uid://:源文件移动/改名后本表依然有效(UID 稳定),只有增删条目、\n"
		+ "## 改 id_override / 分组 / 层级等登记信息才需要重新生成。\n"
		+ "\n"
	)


static func _consts(rows: Array) -> String:
	var out: String = ""
	for row: Dictionary in rows:
		out += "const %s: StringName = &\"%s\"\n" % [row["const_name"], row["id"]]
	return out


static func _emit_scenes(rows: Array) -> String:
	var out: String = _header("Scenes", _SCENE_SOURCE) + _consts(rows) + "\n"
	out += "## id → { uid(加载键), path(仅日志/可读性), group(资产分组) }。\n"
	out += "const _TABLE: Dictionary = {\n"
	for row: Dictionary in rows:
		var entry: Resource = row["entry"]
		var group_name: StringName = entry.get("asset_group")
		out += "\t%s: { \"uid\": \"%s\", \"path\": \"%s\", \"group\": &\"%s\" },\n" % [row["const_name"], row["uid"], row["path"], group_name]
	out += "}\n"
	return out + _COMMON_FUNCS + _SCENE_FUNCS


static func _emit_uis(rows: Array) -> String:
	var out: String = _header("Uis", _UI_SOURCE) + _consts(rows) + "\n"
	out += "## id → { uid(加载键), path(仅日志/可读性), layer(渲染层), cache(缓存策略) }。\n"
	out += "const _TABLE: Dictionary = {\n"
	for row: Dictionary in rows:
		var entry: Resource = row["entry"]
		var layer_name: String = UIRegistryEntry.Layer.keys()[int(entry.get("layer"))]
		var cache_name: String = UIRegistryEntry.Cache.keys()[int(entry.get("cache"))]
		out += "\t%s: { \"uid\": \"%s\", \"path\": \"%s\", \"layer\": UIRegistryEntry.Layer.%s, \"cache\": UIRegistryEntry.Cache.%s },\n" % [row["const_name"], row["uid"], row["path"], layer_name, cache_name]
	out += "}\n"
	return out + _COMMON_FUNCS + _UI_FUNCS


static func _emit_assets(rows: Array) -> String:
	var out: String = _header("Assets", _ASSET_SOURCE) + _consts(rows) + "\n"
	out += "## id → { uid(加载键), path(仅日志/可读性), group(资产分组) }。\n"
	out += "const _TABLE: Dictionary = {\n"
	var groups: Dictionary = {}   # 分组 → [常量名],保持首次出现顺序
	for row: Dictionary in rows:
		var entry: Resource = row["entry"]
		var group_name: StringName = entry.get("group")
		out += "\t%s: { \"uid\": \"%s\", \"path\": \"%s\", \"group\": &\"%s\" },\n" % [row["const_name"], row["uid"], row["path"], group_name]
		if not groups.has(group_name):
			groups[group_name] = []
		(groups[group_name] as Array).append(String(row["const_name"]))
	out += "}\n\n"
	out += "## 分组 → 组内 id 列表(生成期预计算,按组预载/释放遍历用)。\n"
	out += "const _GROUPS: Dictionary = {\n"
	for group_name: StringName in groups:
		var names: Array = groups[group_name]
		out += "\t&\"%s\": [%s],\n" % [group_name, ", ".join(PackedStringArray(names))]
	out += "}\n"
	return out + _COMMON_FUNCS + _ASSET_FUNCS
