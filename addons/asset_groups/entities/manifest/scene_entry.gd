@tool
class_name SceneEntry
extends Resource

## 编辑态场景条目:Dock Scenes 页直接读写,Generate 时写入 [SceneRegistryEntry]。

#region Exports & State
@export var id: StringName = &""
@export var scene_path: String = ""
@export var asset_group: StringName = &""
#endregion
