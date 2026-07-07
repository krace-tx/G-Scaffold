@tool
class_name RegistryLogger
extends RefCounted

## Registry Studio 编辑器日志,与宿主 [LogService] 解耦。

#region Constants & Enums
const PREFIX := "[Registry Studio]"
#endregion

#region Public API
static func info(p_message: String) -> void:
	print("%s %s" % [PREFIX, p_message])


static func warn(p_message: String) -> void:
	push_warning("%s %s" % [PREFIX, p_message])


static func error(p_message: String) -> void:
	push_error("%s %s" % [PREFIX, p_message])
#endregion
