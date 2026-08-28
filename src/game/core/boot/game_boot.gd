class_name GameBoot
extends RefCounted

## 游戏业务层启动管理器。
## 集中管理并装配游戏启动时需要执行的 [BootStage] 阶段列表。


## 游戏启动阶段列表（按执行顺序装配）
static func stages() -> Array[BootStage]:
	return [
		GameSettingStage.new(),
		GameConfigStage.new(),
		GameProfileStage.new(),
		GameAssetStage.new(),
		GamePlatformStage.new(),
	]


## 执行游戏业务启动管线（复用框架 [BootPipeline]）
static func run(on_progress: Callable = Callable()) -> Result:
	return await BootPipeline.new(stages()).run(on_progress)
