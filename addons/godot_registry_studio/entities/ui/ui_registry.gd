class_name UIRegistry
extends Resource

## UI 注册表(唯一权威数据源),数据实例为 res://src/resource/data/ui_registry.tres。
##
## 新增界面:在 Registry Studio 面板登记,或 Inspector 里给 [member entries] 加 [UIRegistryEntry],
## 然后由面板生成 [code]Uis[/code] 常量类。
##
## [b]运行时不得 load 本资源[/b]——条目直接引用 PackedScene,加载本表会把所有
## 界面同步拉进内存。运行时查表一律走生成的 [Uis]。

#region Exports & State
@export var entries: Array[UIRegistryEntry] = []
#endregion
