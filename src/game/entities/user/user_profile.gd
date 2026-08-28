class_name UserProfile
extends Resource

## 玩家个人档案数据实体。
## 记录玩家个人的主线关卡进度以及局内可用道具持有量。

#region Main Progress
@export var current_level: int = 1				## 当前玩家进行到的主线关卡编号（从 1 开始递增）
@export var current_level_viewed: bool = false	## 当前主线关卡是否已展示过开局拼图预览
#endregion

#region Consumable Inventory
@export var preview_count: int = 1				## 关卡局内整图预览剩余可用次数
@export var hint_count: int = 3					## 关卡局内拼图碎片交换提示（Hint）道具剩余数量
@export var add_time_count: int = 1				## 限时关卡局内倒计时加时道具剩余数量
#endregion

## JSON 字段名 → 自定义 Resource 脚本路径映射表。
const SCRIPT_PATHS := {
	"": "res://src/game/entities/user/user_profile.gd",
}


#region Codec
## 将当前实体编码为 JSON 兼容的字典格式。
func encode() -> Dictionary:
	return ResourceCodecUtils.encode(self)


## 从字典数据解码还原为 [UserProfile] 实体对象。
static func decode(encoded: Dictionary, script_paths: Dictionary = SCRIPT_PATHS) -> UserProfile:
	return ResourceCodecUtils.decode(encoded, script_paths) as UserProfile


## 克隆一份当前实体的独立深拷贝副本。
func clone() -> UserProfile:
	return ResourceCodecUtils.clone(self, SCRIPT_PATHS) as UserProfile
#endregion


#region Persist Route
const _STORAGE_ITEM_KEY := &"user_profile"

## 本实体的本地持久化路由描述项。
static func storage_item() -> StorageItem:
	var item := StorageItem.new()
	item.key_id = _STORAGE_ITEM_KEY
	item.disk_path = StorageCatalog.USER_PROFILE
	return item
#endregion
