class_name UIRegistry
extends Resource

## UI id → 记录的注册表,数据实例为 res://src/resource/data/ui_registry.tres。
##
## UIService 只认 [member entries] 里登记过的 id,新增界面时改这份 .tres
## (在编辑器 Inspector 里增删 [UIRegistryEntry]),不改代码。

#region Exports & State
@export var entries: Array[UIRegistryEntry] = []
#endregion

#region Public API
## 查找 [param id] 对应的记录,不存在时返回 null。
func find(id: StringName) -> UIRegistryEntry:
	for entry in entries:
		if entry.id == id:
			return entry
	return null
#endregion
