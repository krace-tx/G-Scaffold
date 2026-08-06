class_name PrefabService
extends Node

## UI Service: 基于 tscn 路径的场景模版加载与缓存管理。

# 缓存字典：path (String) -> PackedScene
var _cache: Dictionary = {}


## 基于 tscn 路径实现对某个场景模版预加载 (load方法)，并把结果进行缓存
@warning_ignore("shadowed_global_identifier")
func load(path: String) -> PackedScene:
	if path.is_empty():
		return null

	if _cache.has(path):
		return _cache[path]

	var scene := ResourceLoader.load(path) as PackedScene
	if scene == null:
		App.log.error("PrefabService", "failed to load scene template: %s" % path)
		return null

	_cache[path] = scene
	return scene


## 基于 tscn 路径获取模版的缓存，如果缓存不存在，触发加载，并返回结果
func get_prefab(path: String) -> PackedScene:
	if _cache.has(path):
		return _cache[path]
	return load(path)
