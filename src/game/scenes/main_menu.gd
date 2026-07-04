class_name MainMenu
extends BaseScene

## 占位主菜单场景,M1 后续里程碑会替换为真正的菜单 UI。
## 目前只用于验证 SceneService 的 enter/exit 生命周期钩子确实被调用。

#region Public API
func _on_enter(_params: Dictionary) -> void:
	App.log.info("main_menu", "entered")


func _on_exit() -> void:
	App.log.info("main_menu", "exited")
#endregion
