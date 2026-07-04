class_name SettingsPanel
extends BaseUI

## 占位设置弹窗,后续里程碑替换为真正的设置界面。
## 目前用于验证 UIService 的 open / close / 返回键(_on_back)三条路径。

#region Public API
func _on_open(_params: Dictionary) -> void:
	App.log.info("settings", "opened")


func _on_close() -> void:
	App.log.info("settings", "closed")
#endregion
