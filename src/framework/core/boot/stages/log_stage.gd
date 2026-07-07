class_name LogStage
extends BootStage

## 阶段 1:日志服务。不可失败(纯本地),必须最先创建。

#region Public API
func get_name() -> String:
	return "Log"


func failure_strategy() -> BootFailureStrategy.Kind:
	return BootFailureStrategy.Kind.FATAL


func run(_ctx: BootContext) -> Result:
	App.log = LogService.new()
	App.log.info(LOG_TAG, "log service ready")
	return Result.ok()
#endregion
