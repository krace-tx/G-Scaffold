@tool
class_name EntryPathUtils
extends RefCounted

## Dock 表单:从资源路径推导 id,并在选取文件时自动填充。

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


## 仅在内容变化时写入,避免重设 [LineEdit.text] 把光标打回行首。
static func set_line_edit_text(edit: LineEdit, text: String) -> void:
	if edit.text == text:
		return
	edit.text = text
#endregion
