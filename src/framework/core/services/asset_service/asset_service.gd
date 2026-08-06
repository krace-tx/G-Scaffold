class_name AssetService
extends Node

## 资产服务:按路径取用、按分组预载/释放。
##
## 目的是**控制内存峰值**:核心资产常驻,场景/关卡资产进场景预载、离场景释放。
## 释放 = 从缓存里丢掉引用,资源在无其他持有者时被引擎回收。见 docs/modules/asset-service.md。
##
## id → 加载键/分组的表在生成的 [Assets] 常量类里(数据源 asset_map.tres),
## 运行时零 .tres 加载,查表纯静态。

#region Exports & State
## 已加载资产缓存:path → Resource。释放 = 从这里 erase(丢引用)。
var _cache: Dictionary = {}
#endregion

#region Public API
## 按路径取资产,已缓存直接返回,未缓存则按需加载并缓存。
func get_asset(path: String) -> Resource:
	if path.is_empty():
		return null
	if _cache.has(path):
		return _cache[path]
	var res := load(path)
	_cache[path] = res
	return res


## 预载某分组的全部资产到缓存(进场景前调用)。空组名或未知分组静默跳过。
func preload_group(group: StringName) -> void:
	if group == &"":
		return
	var count := 0
	for path: String in Assets.paths_in_group(group):
		if not _cache.has(path):
			_cache[path] = load(path)
			count += 1
	App.log.info("AssetService", "preloaded group '%s' (%d assets)" % [group, count])


## 释放某分组的缓存引用(离场景后调用)。资源在无其他持有者时被引擎回收。
func release_group(group: StringName) -> void:
	if group == &"":
		return
	var count := 0
	for path: String in Assets.paths_in_group(group):
		if _cache.has(path):
			_cache.erase(path)
			count += 1
	App.log.info("AssetService", "released group '%s' (%d assets)" % [group, count])


## 某资产当前是否在缓存中。
func is_cached(path: String) -> bool:
	return _cache.has(path)
#endregion
