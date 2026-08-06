@tool
class_name EditAssetEntry
extends Resource

## 编辑态资产条目：仅供 Dock Assets 页读写。Generate 时转换为 [RuntimeAssetEntry]。

#region Exports & State
@export var id: StringName = &""
@export var path: String = ""
## 内存预载分组；空表示未分组。
@export var group: StringName = &""
#endregion
