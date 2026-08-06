@tool
class_name EditSceneEntry
extends Resource

## 编辑态场景条目：仅供 Dock Scenes 页读写，与 [EditUIEntry] 一样只有 id + 路径。
##
## 作为唯一真源 `asset_manifest.tres` 的组成部分。Generate 时转换为
## [RuntimeSceneEntry]，供框架 [SceneService] 消费。

#region Exports & State
@export var id: StringName = &""
@export var scene_path: String = ""
#endregion
