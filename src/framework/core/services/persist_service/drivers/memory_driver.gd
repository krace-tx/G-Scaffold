class_name MemoryDriver 
extends StorageDriver

## 内存存储驱动：负责处理运行时的数据缓存与高级内存生命周期管理。[br]
##
## 槽位、TTL、水位与 LRU 交给 [BudgetCache]。本驱动只做体积估算、[code]memory_ttl[/code] 解析，以及 [Result] 包装。

#region Constants & Enums
## 默认内存上限：32MB（给低端设备留足余量）
const DEFAULT_MAX_BYTES: int = 32 * 1024 * 1024
## 默认缓存过期时长：2 分钟
const DEFAULT_TTL_MSEC: int = 2 * 60 * 1000
## 水位线触发比例：80%（避免顶格才挤压）
const WATERMARK: float = 0.8
## 未知资源类型的占位估算体积（256KB），避免上限被架空
const UNKNOWN_BYTES: int = 256 * 1024
#endregion

#region State
## TTL / 水位 / LRU 由 [BudgetCache] 管。
var _cache: BudgetCache
#endregion

#region Lifecycle
func _init(max_bytes: int = DEFAULT_MAX_BYTES, default_ttl_msec: int = DEFAULT_TTL_MSEC) -> void:
	initialize(max_bytes, default_ttl_msec)

## 初始化内存池配置（供 PersistService 初始化时注入）
func initialize(max_bytes: int = DEFAULT_MAX_BYTES, default_ttl_msec: int = DEFAULT_TTL_MSEC) -> void:
	_cache = BudgetCache.new(max_bytes, default_ttl_msec, WATERMARK)
#endregion

#region Overrides
## 从内存读取数据，命中时自动续期访问时间戳 (LRU)。
func read(key: StringName, _kwargs: Dictionary = {}) -> Result:
	var cached: Variant = _cache.read(key)
	if cached == null:
		return Result.err(ERR_DOES_NOT_EXIST)
	return Result.ok(cached)


## 写入内存，自动估算体积并触发水位线与 LRU 淘汰。
func write(key: StringName, data: Variant, kwargs: Dictionary = {}) -> Result:
	if data == null:
		return Result.err("Write failed: data is null")
		
	var new_bytes := MemoryUtils.estimate_bytes(data)
	
	# 解析 TTL（优先取 kwargs 里的 memory_ttl 秒数，<= 0 表示常驻不按 TTL 过期）
	var item_ttl_sec: float = kwargs.get("memory_ttl", -1.0)
	var ttl_msec: int = -1
	if item_ttl_sec > 0.0:
		ttl_msec = int(item_ttl_sec * 1000.0)
	elif item_ttl_sec == 0.0:
		ttl_msec = 0
	# item_ttl_sec < 0 保持 -1 (常驻)
	
	if _cache.put(key, data, new_bytes, ttl_msec):
		return Result.ok()
	return Result.err("Memory limit exceeded: entry is larger than available capacity")


## 检查内存中是否存在且未过期
func has(key: StringName) -> Result:
	return Result.ok(_cache.has(key))


## 从内存中物理移除指定 key
func delete(key: StringName) -> Result:
	if _cache.drop(key):
		return Result.ok()
	return Result.err(ERR_DOES_NOT_EXIST)
#endregion

#region Public API
## 释放指定 key 的内存缓存槽
func release(key: StringName) -> void:
	_cache.drop(key)


## 清空所有内存缓存（供游戏退出或场景清理时调用）
func clear() -> void:
	_cache.clear()
#endregion
