class_name SceneRegistry
extends Resource

## 场景注册表(唯一权威数据源),数据实例为 res://src/resource/data/scene_registry.tres。
##
## 新增场景:在编辑器 Inspector 里给 [member entries] 加一条 [SceneRegistryEntry],
## 把 .tscn 拖进去,然后跑一次生成器得到 [Scenes] 常量类(见 tools/registry_codegen.gd)。
##
## [b]运行时不得 load 本资源[/b]——条目直接引用 PackedScene,加载本表会把所有
## 场景同步拉进内存。运行时查表一律走生成的 [Scenes](src/resource/generated/),
## 那边只存 uid/路径字符串,SceneService 才能按需异步加载。

#region Exports & State
@export var entries: Array[SceneRegistryEntry] = []
#endregion
