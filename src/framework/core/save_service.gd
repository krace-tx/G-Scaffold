class_name SaveService
extends RefCounted

## 玩家存档:版本化 JSON + 逐级迁移链 + 损坏兜底。见 ADR-0003。
##
## 存档结构固定为 [code]{ "version": N, "data": {...} }[/code]。加载时若文件版本低于
## [constant CURRENT_VERSION],按 [member _migrations] 逐级升级。**禁止把 Resource
## 序列化进 user://**(可注入脚本 + 版本脆弱)。
##
## 数据键一律用 String(JSON 原生键类型),不要用 StringName——JSON 往返后键会变回
## String,用 StringName 读会静默 miss。

#region Constants & Enums
## 代码认识的存档结构版本。加字段/改结构时 +1,并在游戏侧注册对应的迁移函数。
const CURRENT_VERSION: int = 1
## user:// 运行时数据路径,非 res:// 资源,不属于注册表/生成常量类体系。
const _SAVE_PATH: String = "user://save.json"
#endregion

#region Exports & State
## 内存中的存档数据(即 {version,data} 里的 data 部分)。
var _data: Dictionary = {}

## 迁移表:版本 N → [Callable] (data: Dictionary) -> Dictionary,把结构从 N 升到 N+1。
## 框架自带为空;具体游戏在启动时用 [method set_migrations] 注册自己的迁移链。
var _migrations: Dictionary = {}
#endregion

#region Public API
## 从磁盘加载存档并迁移到最新版本。文件不存在→空档;损坏(JSON 解析失败)→备份后走空档;
## 仅当磁盘 I/O 无法读取(非损坏)时返回 err,供 Bootstrap 阶段 2 阻断重试。
func load_or_create() -> Result:
	if not FileAccess.file_exists(_SAVE_PATH):
		App.log.info("save", "no save file, starting fresh")
		_data = {}
		return Result.ok(_data)

	var text := FileAccess.get_file_as_string(_SAVE_PATH)
	if text.is_empty():
		var open_err := FileAccess.get_open_error()
		if open_err != OK:
			return Result.err("存档读取失败(I/O err=%d)" % open_err)
		_data = {}
		return Result.ok(_data)

	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		_backup_corrupt(text)
		App.log.error("save", "corrupt save backed up, starting fresh")
		_data = {}
		return Result.ok(_data)

	_data = _extract_and_migrate(parsed)
	return Result.ok(_data)


## 把内存存档写回磁盘。返回 Result(写失败 err)。
func flush() -> Result:
	var payload := {"version": CURRENT_VERSION, "data": _data}
	var file := FileAccess.open(_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return Result.err("存档写入失败(err=%d)" % FileAccess.get_open_error())
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return Result.ok()


## 读取存档字段([param key] 用 String);不存在返回 [param default]。
func get_value(key: String, default: Variant = null) -> Variant:
	return _data.get(key, default)


## 写入存档字段(仅改内存,持久化需再调 [method flush])。
func set_value(key: String, value: Variant) -> void:
	_data[key] = value


## 清空存档(内存 + 磁盘)。主要供调试面板"清档"用,慎用。返回 flush 的 Result。
func wipe() -> Result:
	_data = {}
	return flush()


## 导出当前存档为格式化 JSON 文本(供调试面板查看/反馈附带)。
func to_json() -> String:
	return JSON.stringify({"version": CURRENT_VERSION, "data": _data}, "\t")


## 注册迁移链(游戏启动时调用)。[param migrations] 为 {版本N: Callable(data)->data}。
func set_migrations(migrations: Dictionary) -> void:
	_migrations = migrations
#endregion

#region Internal
## 从已解析的 payload 里取出 data 并迁移到 CURRENT_VERSION。
func _extract_and_migrate(payload: Dictionary) -> Dictionary:
	var file_version: int = int(payload.get("version", 0))
	var data_v: Variant = payload.get("data", {})
	var data: Dictionary = data_v if data_v is Dictionary else {}
	if file_version < CURRENT_VERSION:
		data = _run_migrations(data, file_version, CURRENT_VERSION, _migrations)
		App.log.info("save", "migrated save %d -> %d" % [file_version, CURRENT_VERSION])
	return data


## 逐级应用迁移:from_version → to_version,每步调 migrations[v]。纯函数,便于单测。
static func _run_migrations(data: Dictionary, from_version: int, to_version: int, migrations: Dictionary) -> Dictionary:
	var v := from_version
	while v < to_version:
		if migrations.has(v):
			data = migrations[v].call(data)
		v += 1
	return data


## 损坏存档备份为 user://save.corrupt.<时间戳>.json,绝不静默丢弃玩家数据。
func _backup_corrupt(text: String) -> void:
	var path := "user://save.corrupt.%d.json" % int(Time.get_unix_time_from_system())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(text)
		f.close()
#endregion
