class_name UIRegistry
extends Resource

## UI 注册表(唯一权威数据源),数据实例为 res://src/resource/data/ui_registry.tres。
##
## 新增界面:Inspector 里给 [member entries] 加一条 [UIRegistryEntry],拖 .tscn、
## 选层级/缓存策略,然后跑一次生成器得到 [Uis] 常量类(见 tools/registry_codegen.gd)。
##
## [b]运行时不得 load 本资源[/b]——条目直接引用 PackedScene,加载本表会把所有
## 界面同步拉进内存。运行时查表一律走生成的 [Uis](src/resource/generated/)。

#region Exports & State
@export var entries: Array[UIRegistryEntry] = []
#endregion
