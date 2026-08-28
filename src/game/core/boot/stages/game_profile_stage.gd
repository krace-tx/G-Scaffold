class_name GameProfileStage
extends BootStage

## 玩家个人档案加载阶段。
## 委托 [Game.profile] 从本地磁盘恢复玩家进度与道具持有量。


func id() -> String:
	return "GameProfile"


func run(_on_progress: Callable = Callable()) -> Result:
	await Game.profile.load_async()
	info("UserProfile loaded: current_level=%d, hint=%d, add_time=%d" % [
		Game.profile.current_level,
		Game.profile.hint_count,
		Game.profile.add_time_count,
	])
	return Result.ok()
