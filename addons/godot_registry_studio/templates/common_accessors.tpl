static func has_id(id: StringName) -> bool:
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
	return _TABLE[id].get("path", "") as String
