class_name GameConfig
extends Resource

## 游戏全局配置根数据实体（服务端下发）。
## 聚合关卡相册配置、系统调优参数与玩家初始档案等所有只读配置数据。

#region Version Constraints
@export var server_version: String = ""			## 服务端下发的配置数据版本号（Server Version）
@export var client_min_version: String = ""		## 服务端要求的客户端 App 最低运行版本号（Client Min Version）
#endregion

#region Sub-Configs
@export var level_config: LevelConfig			## 关卡与主题相册总配置
@export var system_config: SystemConfig			## 系统行为调优配置
@export var user_profile: UserProfile			## 新玩家默认档案与初始道具规则
#endregion


#region Lifecycle
## 预实例化嵌套对象，保证在任何时刻访问子配置对象均不为 null。
func _init() -> void:
	if level_config == null:
		level_config = LevelConfig.new()
	if system_config == null:
		system_config = SystemConfig.new()
	if user_profile == null:
		user_profile = UserProfile.new()
#endregion


#region Codec
const SCRIPT_PATHS := {
	"": "res://src/game/entities/config/game_config.gd",
	"level_config": "res://src/game/entities/config/level_config.gd",
	"system_config": "res://src/game/entities/config/system_config.gd",
	"user_profile": "res://src/game/entities/user/user_profile.gd",
}


## 将当前实体编码为 JSON 兼容的字典格式。
func encode() -> Dictionary:
	return ResourceCodecUtils.encode(self)


## 从字典数据解码还原为 [GameConfig] 实体对象。
static func decode(encoded: Dictionary, script_paths: Dictionary = SCRIPT_PATHS) -> GameConfig:
	return ResourceCodecUtils.decode(encoded, script_paths) as GameConfig


## 克隆一份当前实体的独立深拷贝副本。
func clone() -> GameConfig:
	return ResourceCodecUtils.clone(self, SCRIPT_PATHS) as GameConfig
#endregion


#region Persist Route
const _STORAGE_ITEM_KEY := &"game_config"

## 本实体的持久化路由描述项（包含本地磁盘路径与远端 API 请求 URL）。
static func storage_item() -> StorageItem:
	var item := StorageItem.new()
	item.key_id = _STORAGE_ITEM_KEY
	item.disk_path = StorageCatalog.GAME_CONFIG
	item.remote_url = "%s?current_client_version=%s&device_id=%s" % [
		ApiCatalog.GAME_CONFIG,
		VersionUtils.current(),
		OS.get_unique_id(),
	]
	item.method = "GET"
	return item
#endregion
