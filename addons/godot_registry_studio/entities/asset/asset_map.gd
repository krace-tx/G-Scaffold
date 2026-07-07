class_name AssetMap
extends Resource

## 资产注册表(唯一权威数据源),数据实例为 res://src/resource/data/asset_map.tres。
##
## 新增资产:在 Registry Studio 面板登记,或 Inspector 里给 [member entries] 加 [AssetMapEntry],
## 然后由面板生成 [code]Assets[/code] 常量类。
##
## [b]运行时不得 load 本资源[/b]——条目直接引用资源本体,加载本表会把所有
## 资产同步拉进内存。运行时查表一律走生成的 [Assets]。

#region Exports & State
@export var entries: Array[AssetMapEntry] = []
#endregion
