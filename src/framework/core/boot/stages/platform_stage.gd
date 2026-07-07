class_name PlatformStage
extends BootStage

## 阶段 3:平台 SDK 并行初始化(5s 超时)。失败在 PlatformService 内降级为 Null。

#region Public API
func get_name() -> String:
	return "Platform"


func failure_strategy() -> BootFailureStrategy.Kind:
	return BootFailureStrategy.Kind.DEGRADE


func run(_ctx: BootContext) -> Result:
	var platform := PlatformService.new()
	NodeUtils.mount_required(platform, App, "PlatformService")
	App.platform = platform
	await platform.setup()
	App.log.info(LOG_TAG, "platform sdks ready")
	return Result.ok()
#endregion
