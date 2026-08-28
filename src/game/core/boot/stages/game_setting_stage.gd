class_name GameSettingStage
extends BootStage

## 游戏设置加载阶段。
## 从本地磁盘恢复玩家偏好并初始化 [Game.setting]，同时生效底层音频静音。


func id() -> String:
	return "GameSetting"


func run(_on_progress: Callable = Callable()) -> Result:
	await Game.setting.load_async()
	info("Setting loaded: music=%s, sfx=%s, vibrate=%s" % [
		Game.setting.music_on,
		Game.setting.sfx_on,
		Game.setting.vibrate_on
	])
	return Result.ok()
