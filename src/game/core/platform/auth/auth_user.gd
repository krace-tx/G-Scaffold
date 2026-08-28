class_name AuthUser
extends RefCounted

## 登录用户信息领域实体。

var uid: String = ""
var email: String = ""
var provider: String = ""           ## 登录渠道 (GOOGLE / APPLE / MOCK)
var id_token: String = ""
var refresh_token: String = ""
var raw_data: Dictionary = {}


static func create(p_uid: String, p_email: String, p_provider: String, p_data: Dictionary = {}) -> AuthUser:
	var user := AuthUser.new()
	user.uid = p_uid
	user.email = p_email
	user.provider = p_provider
	user.id_token = str(p_data.get("idToken", ""))
	user.refresh_token = str(p_data.get("refreshToken", ""))
	user.raw_data = p_data
	return user
