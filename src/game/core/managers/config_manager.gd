class_name ConfigManager
extends RefCounted

## 游戏全局配置业务管理器。
## 持有 [GameConfig] 远端配置实体，负责双端版本校验、离线缓存恢复与远端配置拉取更新。

signal loaded(config: GameConfig)

var data: GameConfig = GameConfig.new()


#region Version & Compatibility
## 服务端下发的配置数据版本号
var server_version: String:
	get:
		return data.server_version


## 客户端最低兼容运行版本号
var client_min_version: String:
	get:
		return data.client_min_version


## 当前安装的客户端版本是否过低，需要进行强制更新
func is_force_update() -> bool:
	if client_min_version.is_empty():
		return false
	return VersionUtils.is_lower(VersionUtils.current(), client_min_version)
#endregion


#region Sub-Configs Access
## 获取关卡与主题相册总配置
var level_config: LevelConfig:
	get:
		return data.level_config


## 获取系统行为与调优配置
var system_config: SystemConfig:
	get:
		return data.system_config


## 获取新玩家默认初始档案模板
var default_profile: UserProfile:
	get:
		return data.user_profile
#endregion


#region Persistence & Fetch
## 异步加载配置：远端优先（拉取最新远端配置并自动回灌缓存；离线/弱网自动降级读取本地缓存）
func load_async() -> Result:
	var item := GameConfig.storage_item()
	if App.persist == null:
		return Result.ok(data)

	App.persist.bind(item)
	var res: Result = await App.persist.read_async(item, ReadMode.REMOTE_FIRST)
	# 统一通过 BaseResponse 解析强类型配置实体
	var loaded_config: GameConfig = BaseResponse.parse_data(res.value, GameConfig.decode)
	if loaded_config != null:
		data = loaded_config
		# 确保纯净实体数据正确写入本地磁盘缓存
		await App.persist.write_async(item, data.encode(), WriteMode.LOCAL_ONLY)
		App.log.info("ConfigManager", "GameConfig applied (server_version=%s, client_min=%s)" % [
			data.server_version,
			data.client_min_version,
		])
	else:
		App.log.warn("ConfigManager", "Failed to load GameConfig; fallback to default (server_version=%s)" % data.server_version)

	loaded.emit(data)
	return Result.ok(data)
#endregion
