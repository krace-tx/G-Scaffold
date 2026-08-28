class_name ExampleScene
extends BaseScene

## 演示主场景。
## 展示框架核心服务（SceneService, SettingManager, Toast, Event）的调用范例。

@onready var _env_label: Label = $UI/Margin/VBox/InfoCard/Margin/VBox/EnvLabel
@onready var _host_label: Label = $UI/Margin/VBox/InfoCard/Margin/VBox/HostLabel
@onready var _log_label: Label = $UI/Margin/VBox/LogCard/Scroll/LogLabel

@onready var _open_setting_btn: Button = $UI/Margin/VBox/Actions/Row1/OpenSettingBtn
@onready var _show_toast_btn: Button = $UI/Margin/VBox/Actions/Row1/ShowToastBtn

var _logs: Array[String] = []

func _on_enter(_params: Dictionary = {}) -> void:
	App.log.info("ExampleScene", "Entered ExampleScene")
	_append_log("[INFO] Entered ExampleScene")
	
	_env_label.text = "Environment: " + App.env.get_name()
	_host_label.text = "API Host: " + ApiCatalog.base_host
	
	_open_setting_btn.pressed.connect(_on_open_setting_pressed)
	_show_toast_btn.pressed.connect(_on_show_toast_pressed)


func _on_open_setting_pressed() -> void:
	_append_log("[Popup] Opening ExampleSetting popup...")
	var loaded := await App.asset.load(PopupCatalog.EXAMPLE_SETTING)
	if loaded.is_ok():
		NodeUtils.spawn(loaded.value as PackedScene, self)


func _on_show_toast_pressed() -> void:
	_append_log("[Toast] Spawning toast...")
	var loaded := await App.asset.load(PopupCatalog.TOAST)
	if loaded.is_ok():
		var res := NodeUtils.spawn(loaded.value as PackedScene, self)
		if res.is_ok():
			(res.value as Toast).setup("Hello from G-Scaffold!")


func _append_log(msg: String) -> void:
	_logs.append("[%s] %s" % [Time.get_time_string_from_system(), msg])
	if _logs.size() > 8:
		_logs.pop_front()
	_log_label.text = "\n".join(_logs)
