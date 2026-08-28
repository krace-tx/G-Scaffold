class_name LauncherScene
extends BaseScene

## 脚手架启动入口场景。
## 负责拉起框架层 App.bootstrap() 并推进业务启动管线，完毕后切换到 Example 演示主场景。

@onready var _progress_bar: ProgressBar = $UI/CenterContainer/VBoxContainer/ProgressBar
@onready var _status_label: Label = $UI/CenterContainer/VBoxContainer/StatusLabel

func _ready() -> void:
	App.log.info("Launcher", "=== G-Scaffold App Launch Started ===")
	App.log.info("Launcher", "Environment: %s | Host: %s | OS: %s" % [
		App.env.get_name(),
		ApiCatalog.base_host,
		OS.get_name()
	])
	
	var start_time := Time.get_ticks_msec()
	await App.bootstrap()
	if App.scene.current() != null:
		return
	var res := await App.scene.bind(SceneCatalog.LAUNCHER, self)
	if res.is_err():
		App.log.error("Launcher", "Failed to bind launcher: %s" % String(res.error))
		return
	await _run_launch(start_time)


func _run_launch(start_time: int = 0) -> void:
	_status_label.text = "Loading services..."
	_progress_bar.value = 30.0
	await TimeUtils.wait_safe(self, 0.2)
	
	_status_label.text = "Initializing game..."
	_progress_bar.value = 70.0
	await TimeUtils.wait_safe(self, 0.2)
	
	_status_label.text = "Ready!"
	_progress_bar.value = 100.0
	await TimeUtils.wait_safe(self, 0.1)
	
	var elapsed := Time.get_ticks_msec() - start_time
	App.log.info("Launcher", "Bootstrap finished in %d ms, entering Example scene." % elapsed)
	App.scene.replace(SceneCatalog.EXAMPLE)
