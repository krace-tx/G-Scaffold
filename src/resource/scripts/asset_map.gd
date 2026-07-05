class_name AssetMap
extends Resource

## 资产注册表(唯一权威数据源),数据实例为 res://src/resource/data/asset_map.tres。
##
## 新增资产:Inspector 里给 [member entries] 加一条 [AssetMapEntry],拖资源文件、
## 填分组,然后跑一次生成器得到 [Assets] 常量类(见 tools/registry_codegen.gd)。
##
## [b]运行时不得 load 本资源[/b]——条目直接引用资源本体,加载本表会把所有
## 资产同步拉进内存。运行时查表一律走生成的 [Assets](src/resource/generated/)。

#region Exports & State
@export var entries: Array[AssetMapEntry] = []
#endregion
