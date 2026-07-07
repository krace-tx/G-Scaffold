@tool
class_name AssetEntry
extends Resource

## 编辑态资产条目:Dock Assets 页直接读写,Generate 时写入 [AssetMapEntry]。

#region Exports & State
@export var id: StringName = &""
@export var path: String = ""
@export var group: StringName = &"core"
#endregion
