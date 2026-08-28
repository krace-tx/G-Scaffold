class_name UserProfile
extends RefCounted

## 通用玩家档案实体。
## 纯数据对象，仅负责字段定义、序列化与反序列化。

#region Fields
var user_id: String = ""
var nickname: String = "Player"
var avatar_url: String = ""
var created_at: int = 0
var last_login_at: int = 0
#endregion


#region Serialization
func to_dict() -> Dictionary:
	return {
		"user_id": user_id,
		"nickname": nickname,
		"avatar_url": avatar_url,
		"created_at": created_at,
		"last_login_at": last_login_at,
	}


func from_dict(dict: Dictionary) -> void:
	if dict.is_empty():
		return
	user_id = str(dict.get("user_id", user_id))
	nickname = str(dict.get("nickname", nickname))
	avatar_url = str(dict.get("avatar_url", avatar_url))
	created_at = int(dict.get("created_at", created_at))
	last_login_at = int(dict.get("last_login_at", last_login_at))


func get_storage_key() -> String:
	return StorageCatalog.USER_PROFILE
#endregion
