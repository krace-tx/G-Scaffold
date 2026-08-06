@tool
class_name EditResourceEntry
extends Resource

#region Exports & State
@export var id: StringName = &""
@export var path: String = ""
## 内存预载分组；空表示未分组。
@export var group: StringName = &""
#endregion
