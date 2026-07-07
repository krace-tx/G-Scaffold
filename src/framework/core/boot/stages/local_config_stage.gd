class_name LocalConfigStage
extends BootStage

## 阶段 2a:权威时间源 + 本地配置加载。

#region Public API
func get_name() -> String:
	return "LocalConfig"


func failure_strategy() -> BootFailureStrategy.Kind:
	return BootFailureStrategy.Kind.FATAL


func run(_ctx: BootContext) -> Result:
	App.time = TimeService.new()

	App.config = ConfigService.new()
	App.config.load_local()

	App.log.info(LOG_TAG, "time & local config ready")
	return Result.ok()
#endregion
