class_name AssetStage
extends BootStage

## 阶段 5:常驻资产(&"core" 组)预热。

#region Public API
func get_name() -> String:
	return "Asset"


func failure_strategy() -> BootFailureStrategy.Kind:
	return BootFailureStrategy.Kind.FATAL


func run(_ctx: BootContext) -> Result:
	App.assets.preload_group(&"core")
	App.log.info(LOG_TAG, "core assets preloaded")
	return Result.ok()
#endregion
