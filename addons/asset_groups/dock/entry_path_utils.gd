@tool
class_name EntryPathUtils
extends RefCounted

## Dock 表单:从资源路径推导 id,并在选取/拖拽文件时按规则自动填充。

const SCENE_EXTENSIONS: PackedStringArray = ["tscn"]

const ASSET_EXTENSIONS: PackedStringArray = [
	"png", "jpg", "jpeg", "webp", "svg", "bmp", "tga",
	"wav", "ogg", "mp3",
	"ttf", "otf", "woff", "woff2",
	"glb", "gltf", "obj", "fbx",
	"atlas", "bin", "dat", "json", "csv", "txt",
	"tres", "res", "material", "shader", "gdshader",
]

#region Public API
static func basename_id(path: String) -> String:
	if path.is_empty():
		return ""
	return path.get_file().get_basename()


## id 为空或为 Add 生成的 new_* 占位符时,允许用文件名覆盖。
static func should_autofill_id(current_id: StringName) -> bool:
	if current_id == &"":
		return true
	return String(current_id).begins_with("new_")


## [param is_taken] 接收 StringName,返回该 id 是否已被其他条目占用。
static func unique_id(base: String, is_taken: Callable) -> StringName:
	var candidate := base if not base.is_empty() else "unnamed"
	var n := 1
	while is_taken.call(StringName(candidate)):
		n += 1
		candidate = "%s_%d" % [base if not base.is_empty() else "unnamed", n]
	return StringName(candidate)


## 选取/拖拽路径后决定是否用文件名覆盖 id(空 id 或 new_* 占位符才覆盖)。
static func resolve_id_after_path_pick(
	path: String,
	current_id: StringName,
	is_taken: Callable
) -> StringName:
	if path.is_empty() or not should_autofill_id(current_id):
		return current_id
	return unique_id(basename_id(path), is_taken)


## FileSystem 拖拽 payload 是否包含至少一个允许扩展名的 res:// 文件。
static func can_accept_files_drop(data: Variant, extensions: PackedStringArray) -> bool:
	return not first_dropped_path(data, extensions).is_empty()


## 从 FileSystem 拖拽数据里取第一个匹配扩展名的 res:// 路径。
static func first_dropped_path(data: Variant, extensions: PackedStringArray) -> String:
	if typeof(data) != TYPE_DICTIONARY:
		return ""
	var drop_type: String = str(data.get("type", ""))
	if drop_type != "files" and drop_type != "files_and_dirs":
		return ""
	var files: Variant = data.get("files", [])
	if typeof(files) != TYPE_ARRAY:
		return ""
	for item in files as Array:
		var path := str(item)
		if path.is_empty() or not path.begins_with("res://"):
			continue
		if _path_extension(path) in extensions:
			return path
	return ""


static func file_dialog_filters(extensions: PackedStringArray) -> PackedStringArray:
	var globs: PackedStringArray = []
	for ext in extensions:
		globs.append("*.%s" % ext)
	return PackedStringArray(["; ".join(globs) + " ; Resources"])


## 仅在内容变化时写入,避免重设 [LineEdit.text] 把光标打回行首。
static func set_line_edit_text(edit: LineEdit, text: String) -> void:
	if edit.text == text:
		return
	edit.text = text
#endregion

#region Helpers
static func _path_extension(path: String) -> String:
	return path.get_file().get_extension().to_lower()
#endregion
