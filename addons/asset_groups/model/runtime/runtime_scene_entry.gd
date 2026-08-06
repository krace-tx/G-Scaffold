@tool
class_name RuntimeSceneEntry
extends Resource

## 运行时场景注册表的一条登记,由 [RegistryGenerator] 从 [EditSceneEntry] 生成。
##
## 存路径字符串而非 PackedScene 引用,避免 load 本表时把所有场景同步拉进内存。

#region Exports & State
@export var id: StringName = &""
@export var scene_path: String = ""
#endregion
