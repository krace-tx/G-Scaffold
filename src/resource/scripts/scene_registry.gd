class_name SceneRegistry
extends Resource

## 场景 id → 路径的注册表,数据实例为 res://src/resource/data/scene_registry.tres。
##
## SceneService 只认 [member entries] 里登记过的 id,新增场景时改这份 .tres
## (在编辑器 Inspector 里增删 [SceneRegistryEntry]),不改代码。

#region Exports & State
@export var entries: Array[SceneRegistryEntry] = []
#endregion

#region Public API
## 查找 [param id] 对应的场景路径,不存在时返回空字符串。
##
## 命名为 resolve_path 而不是 get_path——Resource 自带一个签名不同的内置
## get_path()(返回这个 .tres 资源文件自身的磁盘路径),撞名会被 GDScript
## 判定为签名不匹配的覆写,必须换名,不是简单加 @warning_ignore 能解决的。
func resolve_path(id: StringName) -> String:
	for entry in entries:
		if entry.id == id:
			return entry.scene_path
	return ""
#endregion
