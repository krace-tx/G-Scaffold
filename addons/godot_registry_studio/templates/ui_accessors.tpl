## 界面所属渲染层;未登记返回 WINDOW。
static func layer(id: StringName) -> UIRegistryEntry.Layer:
	if not _TABLE.has(id):
		return UIRegistryEntry.Layer.WINDOW
	return _TABLE[id].get("layer", UIRegistryEntry.Layer.WINDOW) as UIRegistryEntry.Layer


## 界面关闭时的缓存策略;未登记返回 DESTROY。
static func cache(id: StringName) -> UIRegistryEntry.Cache:
	if not _TABLE.has(id):
		return UIRegistryEntry.Cache.DESTROY
	return _TABLE[id].get("cache", UIRegistryEntry.Cache.DESTROY) as UIRegistryEntry.Cache
