@tool
class_name AssetMap
extends Resource

## 运行时资产注册表,数据实例为 res://src/resource/data/asset_map.tres。
##
## 由 Asset Groups 面板 Generate 从 [AssetManifest] 全量重建;运行时不得 load 本资源,
## 查表一律走生成的 [Assets] 常量类。

#region Exports & State
@export var entries: Array[AssetMapEntry] = []
#endregion
