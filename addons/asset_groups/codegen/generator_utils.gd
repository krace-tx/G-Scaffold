class_name AssetGroupsGeneratorUtils
extends Object

## 生成器共用:目录创建、文件写入、资源 UID 解析。

static var _ident_re: RegEx
static var _load_key_cache: Dictionary = {}

#region Public API
static func begin_resolve_batch() -> void:
	_load_key_cache.clear()


static func ensure_parent_dir(path: String) -> String:
	var global_dir := ProjectSettings.globalize_path(path.get_base_dir())
	if DirAccess.make_dir_recursive_absolute(global_dir) != OK:
		return "无法创建目录 %s" % path.get_base_dir()
	return ""


static func write_text(path: String, content: String) -> String:
	var dir_err := ensure_parent_dir(path)
	if dir_err != "":
		return dir_err
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return "无法写入 %s(错误码 %d)" % [path, FileAccess.get_open_error()]
	file.store_string(content)
	file.close()
	return ""


## 精准刷新已改动的产物路径,避免全项目 [code]scan()[/code]。
static func refresh_generated_files(file_paths: PackedStringArray) -> void:
	if file_paths.is_empty():
		return
	var fs := EditorInterface.get_resource_filesystem()
	for path in file_paths:
		fs.update_file(path)


## ResourceLoader 可用的 uid:// 加载键;无 UID 时回退 res:// 路径。
## 批量生成前调用 [method begin_resolve_batch] 以复用缓存。
static func resolve_load_key(res_path: String) -> String:
	if res_path.is_empty():
		return ""
	if _load_key_cache.has(res_path):
		return _load_key_cache[res_path]
	# Godot 4.6+: path_to_uid 直接返回 uid:// 文本;无 UID 时回退原 res:// 路径。
	var key := ResourceUID.path_to_uid(res_path)
	_load_key_cache[res_path] = key
	return key


static func is_valid_identifier(id: StringName) -> bool:
	var text := String(id)
	if text.is_empty():
		return false
	if _ident_re == null:
		_ident_re = RegEx.create_from_string("^[A-Za-z_][A-Za-z0-9_]*$")
	return _ident_re.search(text) != null


## 把文件名等原始文本转成 Generate 可接受的 id(字母/数字/下划线,不以数字开头)。
static func legalize_identifier(raw: String) -> String:
	var text := raw.strip_edges()
	if text.is_empty():
		return "unnamed"

	var out := ""
	for i in text.length():
		var ch := text[i]
		if _is_identifier_char(ch):
			out += ch
		else:
			out += "_"

	while "__" in out:
		out = out.replace("__", "_")
	while out.begins_with("_"):
		out = out.trim_prefix("_")
	while out.ends_with("_"):
		out = out.trim_suffix("_")

	if out.is_empty():
		return "unnamed"
	if out[0] >= "0" and out[0] <= "9":
		out = "_%s" % out
	return out if is_valid_identifier(StringName(out)) else "unnamed"


static func const_name(id: StringName) -> String:
	return String(id).to_upper()


static func _is_identifier_char(ch: String) -> bool:
	return (
		(ch >= "a" and ch <= "z")
		or (ch >= "A" and ch <= "Z")
		or (ch >= "0" and ch <= "9")
		or ch == "_"
	)
#endregion
