class_name VersionUtils
extends RefCounted


## 获取客户端当前版本号（从 ProjectSettings 读取）
static func current_client_version() -> String:
	var project_version := ProjectSettings.get_setting(
		"application/config/version", "1.0.0"
	) as String
	return project_version if not project_version.is_empty() else "1.0.0"


## 检查客户端版本是否满足最低要求
static func is_satisfied(client_version: String, min_version: String) -> bool:
	if min_version.is_empty():
		return true
	return compare(client_version, min_version) >= 0


## 版本号比较，返回 -1 / 0 / 1
static func compare(current: String, minimum: String) -> int:
	var current_parts := current.split(".")
	var minimum_parts := minimum.split(".")

	for i in range(maxi(current_parts.size(), minimum_parts.size())):
		var current_num := int(current_parts[i]) if i < current_parts.size() else 0
		var minimum_num := int(minimum_parts[i]) if i < minimum_parts.size() else 0
		if current_num < minimum_num:
			return -1
		if current_num > minimum_num:
			return 1
	return 0
