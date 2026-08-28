class_name User
extends Resource

## 与后端对接的用户实体（测试用）。[br]
## JSON 字段如何还原成 Resource，由本实体的 [constant SCRIPT_PATHS] 声明，不放进 [StorageItem]。

@export var id: String = ""
@export var nickname: String = ""

## JSON 字段名 → 自定义 Resource 脚本路径。[br]
## 空字符串表示根对象自身；嵌套字段例如 [code]"profile"[/code] → [code]res://.../profile.gd[/code]。
const SCRIPT_PATHS := {
	"": "res://src/test/persist/entity/user.gd",
}


#region Codec
## 编成 Persist 可搬运的 Dictionary。
func encode() -> Dictionary:
	return ResourceCodecUtils.encode(self)


## 从 Dictionary 还原。远端裸 JSON 无 [code]_script_path[/code] 时靠 [constant SCRIPT_PATHS]。
static func decode(encoded: Dictionary) -> User:
	return ResourceCodecUtils.decode(encoded, SCRIPT_PATHS) as User
#endregion


## 本实体的持久化路由。
static func storage_item() -> StorageItem:
	var item := StorageItem.new()
	item.key_id = &"user"
	item.disk_path = "user://test_user.json"
	item.remote_url = "https://example.com/user"
	item.method = "POST"
	return item
