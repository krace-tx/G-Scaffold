@tool
class_name EntryPathLineEdit
extends LineEdit

## 可接收 FileSystem 拖拽的路径输入框;仅接受 [member allowed_extensions] 内的 res:// 文件。

signal path_dropped(path: String)

@export var allowed_extensions: PackedStringArray = PackedStringArray(["tscn"])


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return EntryPathUtils.can_accept_files_drop(data, allowed_extensions)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var path := EntryPathUtils.first_dropped_path(data, allowed_extensions)
	if path.is_empty():
		return
	path_dropped.emit(path)
