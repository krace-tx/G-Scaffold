class_name CoreAssetStage
extends BootStage

#region Public API
func get_name() -> String:
	return "CoreAsset"


func failure_strategy() -> BootFailureStrategy.Kind:
	return BootFailureStrategy.Kind.FATAL


func run(_ctx: BootContext) -> Result:
	App.assets.preload_group(&"core")
	App.log.info(LOG_TAG, "Core assets preloaded")
	return Result.ok()
#endregion
