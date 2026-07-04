class_name AssetService
extends Node

## 资产服务:asset_map(id → 路径 + 分组)、按组预载/释放、按 id 取用。
##
## 目的是**控制内存峰值**:核心资产常驻,场景/关卡资产进场景预载、离场景释放。
## 释放 = 从缓存里丢掉引用,资源在无其他持有者时被引擎回收。见 docs/modules/asset-service.md。

#region Exports & State
## id → 记录的表,_ready 时一次性加载。
var _map: AssetMap

## 已加载资产缓存:id → Resource。释放 = 从这里 erase(丢引用)。
var _cache: Dictionary = {}
#endregion

#region Lifecycle
func _ready() -> void:
	_map = load(ResPaths.ASSET_MAP) as AssetMap
#endregion

#region Public API
## 按 id 取资产,已缓存直接返回,未缓存则按需加载并缓存。id 未登记返回 null。
func get_asset(id: StringName) -> Resource:
	if _cache.has(id):
		return _cache[id]
	var entry := _map.find(id) if _map else null
	if entry == null:
		App.log.error("asset", "unknown asset id: %s" % id)
		return null
	var res := load(entry.path)
	_cache[id] = res
	return res


## 预载某分组的全部资产到缓存(进场景前调用)。空组名或表未加载时静默跳过。
func preload_group(group: StringName) -> void:
	if _map == null or group == &"":
		return
	var count := 0
	for entry in _map.entries:
		if entry.group == group and not _cache.has(entry.id):
			_cache[entry.id] = load(entry.path)
			count += 1
	App.log.info("asset", "preloaded group '%s' (%d assets)" % [group, count])


## 释放某分组的缓存引用(离场景后调用)。资源在无其他持有者时被引擎回收。
func release_group(group: StringName) -> void:
	if _map == null or group == &"":
		return
	var count := 0
	for entry in _map.entries:
		if entry.group == group and _cache.has(entry.id):
			_cache.erase(entry.id)
			count += 1
	App.log.info("asset", "released group '%s' (%d assets)" % [group, count])


## 某资产当前是否在缓存中。
func is_cached(id: StringName) -> bool:
	return _cache.has(id)
#endregion
