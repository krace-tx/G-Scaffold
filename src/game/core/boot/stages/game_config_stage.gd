class_name GameConfigStage
extends BootStage

## 游戏配置加载阶段。
## 委托 [Game.config] 从本地磁盘与服务端拉取最新配置。


func id() -> String:
	return "GameConfig"


func run(_on_progress: Callable = Callable()) -> Result:
	await Game.config.load_async()
	info("GameConfig loaded: server_version=%s, client_min=%s" % [
		Game.config.server_version,
		Game.config.client_min_version,
	])
	return Result.ok()
