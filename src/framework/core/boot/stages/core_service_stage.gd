class_name CoreServiceStage
extends BootStage

## 常驻场景树服务接线:Scene / UI / Asset / Audio。
##
## 不是 boot-sequence 表格里的编号阶段,而是切场景后仍需存活的内核服务;
## 全部挂到 App 下而非 Boot 场景下。

#region Public API
func get_name() -> String:
	return "CoreServices"


func failure_strategy() -> BootFailureStrategy.Kind:
	return BootFailureStrategy.Kind.FATAL


func run(_ctx: BootContext) -> Result:
	var scene_service := SceneService.new()
	NodeUtils.mount_required(scene_service, App, "SceneService")
	App.scenes = scene_service

	var ui_service := UIService.new()
	NodeUtils.mount_required(ui_service, App, "UIService")
	App.ui = ui_service

	var asset_service := AssetService.new()
	NodeUtils.mount_required(asset_service, App, "AssetService")
	App.assets = asset_service

	var audio_service := AudioService.new()
	NodeUtils.mount_required(audio_service, App, "AudioService")
	App.audio = audio_service

	App.log.info(LOG_TAG, "scene, ui, asset & audio services ready")
	return Result.ok()
#endregion
