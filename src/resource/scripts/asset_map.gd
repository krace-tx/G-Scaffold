class_name AssetMap
extends Resource

## 资产 id → 记录的表,数据实例为 res://src/resource/data/asset_map.tres。
##
## AssetService 只认这里登记过的 id,新增资产改这份 .tres(Inspector 里增删
## [AssetMapEntry]),代码用 [code]AssetIds.XXX[/code] 引用,不写裸路径。

#region Exports & State
@export var entries: Array[AssetMapEntry] = []
#endregion

#region Public API
## 查找 [param id] 对应的记录,不存在时返回 null。
func find(id: StringName) -> AssetMapEntry:
	for entry in entries:
		if entry.id == id:
			return entry
	return null
#endregion
