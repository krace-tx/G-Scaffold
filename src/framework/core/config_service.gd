class_name ConfigService
extends RefCounted

## 运营/远程配置的只读访问:三层合并 remote > local > defaults。
##
## 三类值来源,优先级从高到低:
## - remote:本次从服务器下发(M4 接通,启动阶段 4 拉取)
## - local:上次远程结果的本地缓存(离线 / 拉取失败时兜底)
## - defaults:代码内置默认值(最低保障,永远有值)
##
## 数据键用 String(与 JSON 一致)。业务只读,不在运行时改配置——想改行为改数据源。

#region Constants & Enums
## 远程配置的本地缓存路径,user:// 运行时数据(非 res:// 资源)。
const _LOCAL_CACHE_PATH: String = "user://config_cache.json"
#endregion

#region Exports & State
var _defaults: Dictionary = {}   ## 代码默认值,最低优先级
var _local: Dictionary = {}      ## 本地缓存(上次远程结果)
var _remote: Dictionary = {}     ## 本次远程下发,最高优先级
#endregion

#region Public API
## 设置代码内置默认值(游戏启动时调用一次)。
func set_defaults(defaults: Dictionary) -> void:
	_defaults = defaults


## 读取配置,优先级 remote > local > defaults > [param fallback]。
func get_value(key: String, fallback: Variant = null) -> Variant:
	if _remote.has(key):
		return _remote[key]
	if _local.has(key):
		return _local[key]
	if _defaults.has(key):
		return _defaults[key]
	return fallback


func get_bool(key: String, fallback: bool = false) -> bool:
	return bool(get_value(key, fallback))


func get_int(key: String, fallback: int = 0) -> int:
	return int(get_value(key, fallback))


func get_number(key: String, fallback: float = 0.0) -> float:
	return float(get_value(key, fallback))


func get_string(key: String, fallback: String = "") -> String:
	return str(get_value(key, fallback))


## 加载本地缓存(若存在)。Bootstrap 阶段 2 调用,让离线首启也有上次的远程值。
func load_local() -> void:
	if not FileAccess.file_exists(_LOCAL_CACHE_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_LOCAL_CACHE_PATH))
	if parsed is Dictionary:
		_local = parsed


## 应用远程配置并落盘为本地缓存(M4 拉取成功后调用)。
func apply_remote(remote: Dictionary) -> void:
	_remote = remote
	_local = remote
	_save_local_cache()
#endregion

#region Internal
func _save_local_cache() -> void:
	var file := FileAccess.open(_LOCAL_CACHE_PATH, FileAccess.WRITE)
	if file == null:
		App.log.warn("config", "本地缓存写入失败(err=%d)" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(_local, "\t"))
	file.close()
#endregion
