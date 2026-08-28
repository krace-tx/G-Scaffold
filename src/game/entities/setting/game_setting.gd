class_name GameSetting
extends Resource

## 玩家本地偏好设置数据实体。
## 纯粹负责玩家交互设置（音频开关、振动触感、官方外链）的数据结构定义与持久化编解码。

#region Preference Toggles
@export var music_on: bool = true				## 背景音乐（BGM）开关状态
@export var sfx_on: bool = true					## 游戏音效（SFX）开关状态
@export var vibrate_on: bool = true				## 设备触觉振动反馈开关状态
#endregion

#region External Links
@export var privacy_policy_url: String = ""		## 隐私政策网页链接
@export var terms_of_service_url: String = ""	## 服务条款网页链接
@export var contact_us_url: String = ""			## 联系客服/反馈网页链接
#endregion

## JSON 字段名 → 自定义 Resource 脚本路径映射表。
const SCRIPT_PATHS := {
	"": "res://src/game/entities/setting/game_setting.gd",
}


#region Codec
## 将当前实体编码为 JSON 兼容的字典格式。
func encode() -> Dictionary:
	return ResourceCodecUtils.encode(self)


## 从字典数据解码还原为 [GameSetting] 实体对象。
static func decode(encoded: Dictionary, script_paths: Dictionary = SCRIPT_PATHS) -> GameSetting:
	return ResourceCodecUtils.decode(encoded, script_paths) as GameSetting


## 克隆一份当前实体的独立深拷贝副本。
func clone() -> GameSetting:
	return ResourceCodecUtils.clone(self, SCRIPT_PATHS) as GameSetting
#endregion


#region Persist Route
const _STORAGE_ITEM_KEY := &"game_setting"

## 本实体的本地持久化路由描述项。
static func storage_item() -> StorageItem:
	var item := StorageItem.new()
	item.key_id = _STORAGE_ITEM_KEY
	item.disk_path = StorageCatalog.GAME_SETTING
	return item
#endregion
