class_name ProfileManager
extends RefCounted

## 玩家个人档案业务管理器。
## 持有并管理 [UserProfile] 纯数据实体，协调本地持久化存盘与数据变动广播。

signal changed ## 玩家档案数据发生变动时触发

var data: UserProfile = UserProfile.new()


#region Progress
## 当前玩家进行到的主线关卡编号（从 1 开始递增）
var current_level: int:
	get:
		return data.current_level
	set(value):
		if data.current_level == value:
			return
		data.current_level = value
		save_async()
		changed.emit()

## 当前主线关卡是否已展示过开局拼图预览
var current_level_viewed: bool:
	get:
		return data.current_level_viewed
	set(value):
		if data.current_level_viewed == value:
			return
		data.current_level_viewed = value
		save_async()
		changed.emit()
#endregion


#region Consumables
## 关卡局内整图预览剩余可用次数
var preview_count: int:
	get:
		return data.preview_count
	set(value):
		if data.preview_count == value:
			return
		data.preview_count = max(0, value)
		save_async()
		changed.emit()

## 关卡局内拼图碎片交换提示（Hint）道具剩余数量
var hint_count: int:
	get:
		return data.hint_count
	set(value):
		if data.hint_count == value:
			return
		data.hint_count = max(0, value)
		save_async()
		changed.emit()

## 限时关卡倒计时加时道具剩余数量
var add_time_count: int:
	get:
		return data.add_time_count
	set(value):
		if data.add_time_count == value:
			return
		data.add_time_count = max(0, value)
		save_async()
		changed.emit()
#endregion


#region Persistence & Lifecycle
## 异步保存到本地磁盘
func save_async() -> void:
	if App.persist != null:
		await App.persist.write_async(UserProfile.storage_item(), data.encode(), WriteMode.LOCAL_ONLY)


## 异步从本地磁盘读取存档；若无本地存档，则使用服务端配置中的默认初值初始化并落盘
func load_async() -> Result:
	var item := UserProfile.storage_item()
	if App.persist != null:
		App.persist.bind(item)
		var res: Result = await App.persist.read_async(item, ReadMode.LOCAL_ONLY)
		if res.is_ok() and res.value is Dictionary:
			var loaded := UserProfile.decode(res.value as Dictionary)
			if loaded != null:
				data = loaded
				changed.emit()
				return Result.ok(data)

	# 首次启动/无本地存档：采用服务端配置模板进行安全克隆并立即落盘
	if Game != null and Game.config != null and Game.config.default_profile != null:
		data = Game.config.default_profile.clone()
	else:
		data = UserProfile.new()

	await save_async()
	changed.emit()
	return Result.ok(data)
#endregion
