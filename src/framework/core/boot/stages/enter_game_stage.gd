class_name EnterGameStage
extends BootStage

## 阶段 6:进入主菜单。[SceneService.replace] 内部 await 转场,不会撞上 Boot 同帧切场景坑。

#region Public API
func get_name() -> String:
	return "EnterGame"


func failure_strategy() -> BootFailureStrategy.Kind:
	return BootFailureStrategy.Kind.FATAL


func run(_ctx: BootContext) -> Result:
	App.log.info(LOG_TAG, "entering main menu")
	App.scenes.replace(Scenes.MAIN_MENU)
	return Result.ok()
#endregion
