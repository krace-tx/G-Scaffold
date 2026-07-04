class_name Level
extends BaseScene

## 占位空关卡,后续里程碑替换为真正的关卡。
## 目前用于验证 SceneService 在主菜单 ↔ 关卡之间的往返切换。

#region Public API
func _on_enter(_params: Dictionary) -> void:
	App.log.info("level", "entered")
	_build_back_button()


func _on_exit() -> void:
	App.log.info("level", "exited")
#endregion

#region Internal
func _build_back_button() -> void:
	var b := Button.new()
	b.text = "← Back to Menu"
	b.set_anchors_preset(Control.PRESET_TOP_LEFT)
	b.position = Vector2(16, 16)
	b.pressed.connect(func() -> void: App.scenes.replace(SceneIds.MAIN_MENU))
	NodeUtils.mount_required(b, self, "BackButton")
#endregion
