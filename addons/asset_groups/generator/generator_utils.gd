@tool
class_name GeneratorUtils
extends RefCounted

## 生成器共用:目录创建、文件写入、资源 UID 解析。

#region Public API
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


## ResourceLoader 可用的 uid:// 加载键;无 UID 时回退 res:// 路径。
static func resolve_load_key(res_path: String) -> String:
	if res_path.is_empty():
		return ""
	if not ResourceLoader.exists(res_path):
		return ""
	var uid: int = ResourceLoader.get_resource_uid(res_path)
	if uid >= 0:
		return ResourceUID.id_to_text(uid)
	return res_path


static func is_valid_identifier(id: StringName) -> bool:
	var text := String(id)
	if text.is_empty():
		return false
	return RegEx.create_from_string("^[A-Za-z_][A-Za-z0-9_]*$").search(text) != null


static func const_name(id: StringName) -> String:
	return String(id).to_upper()
#endregion
