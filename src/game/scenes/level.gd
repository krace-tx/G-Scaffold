class_name Level
extends BaseScene

## 占位空关卡,后续里程碑替换为真正的关卡。
## 目前用于验证 SceneService 在主菜单 ↔ 关卡之间的往返切换。

#region Public API
func _on_enter(_params: Dictionary) -> void:
	App.log.info("level", "entered")


func _on_exit() -> void:
	App.log.info("level", "exited")
#endregion
