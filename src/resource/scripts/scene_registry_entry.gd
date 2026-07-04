class_name SceneRegistryEntry
extends Resource

## 场景注册表的一条记录:场景 id → 场景文件路径。
##
## 由 [SceneRegistry] 持有一组这样的条目,数据存放在
## res://src/resource/data/scene_registry.tres。故意用路径字符串而不是直接
## 导出 PackedScene 引用——后者会在注册表本身被加载时就同步加载所有场景,
## 而 SceneService 需要按需 [code]ResourceLoader.load_threaded_request[/code]
## 异步加载,只有存路径才能延迟到真正切换时才去读盘。

#region Exports & State
@export var id: StringName = &""
@export var scene_path: String = ""
#endregion
