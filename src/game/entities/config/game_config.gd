class_name GameConfig
extends RefCounted

## 通用游戏远端/本地全局配置实体。
## 纯数据对象，只做属性声明与字典映射序列化，不写任何 IO、网络与业务逻辑。

#region Fields
var system: SystemConfig = SystemConfig.new()
var version: String = "1.0.0"
var raw_data: Dictionary = {}
#endregion


#region Serialization
func to_dict() -> Dictionary:
	return {
		"version": version,
		"system": system.to_dict() if system != null else {},
		"raw_data": raw_data,
	}


func from_dict(dict: Dictionary) -> void:
	if dict.is_empty():
		return
	
	version = str(dict.get("version", version))
	raw_data = dict.get("raw_data", {})
	
	var sys_data: Dictionary = dict.get("system", {})
	if not sys_data.is_empty():
		system = SystemConfig.new()
		system.from_dict(sys_data)


func get_storage_key() -> String:
	return StorageCatalog.GAME_CONFIG
#endregion
