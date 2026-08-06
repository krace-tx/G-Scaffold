class_name AuthProvider
extends PlatformProvider


signal on_auth_succeeded(firebase_uid: String, email: String, uid_source: String, auth_data: Dictionary)
signal on_auth_failed(error_message: String)

#region 配置常量
const GOOGLE_SIGN_IN_SINGLETON := "GodotGoogleSignIn"
const GOOGLE_WEB_CLIENT_ID := (
	"540218110386-71utfsbpmmorev6mg6otd306ck8laf6j.apps.googleusercontent.com"
)
#endregion


#region 变量
var _google_sign_in_plugin: Object = null
var _apple_sign_in_plugin: Object = null
var _apple_sign_in_nonce: String = ""
var _pending_email: String = ""
var _is_logging_in: bool = false
#endregion


func is_logging_in() -> bool:
	return _is_logging_in


#region 生命周期
func initialize() -> bool:
	_init_google_sign_in_plugin()
	_init_apple_sign_in_plugin()
	App.log.info("AuthProvider", "Auth provider initialized")
	return true
#endregion


#region 初始化
func _init_google_sign_in_plugin() -> void:
	if OS.get_name() != "Android":
		return
	if not Engine.has_singleton(GOOGLE_SIGN_IN_SINGLETON):
		App.log.warn("AuthProvider", "GodotGoogleSignIn singleton not found")
		return

	_google_sign_in_plugin = Engine.get_singleton(GOOGLE_SIGN_IN_SINGLETON)
	_google_sign_in_plugin.initialize(GOOGLE_WEB_CLIENT_ID)

	if _google_sign_in_plugin.has_signal("sign_in_success"):
		_google_sign_in_plugin.connect("sign_in_success", _on_google_sign_in_success)
	if _google_sign_in_plugin.has_signal("sign_in_failed"):
		_google_sign_in_plugin.connect("sign_in_failed", _on_google_sign_in_failed)

	App.log.info("AuthProvider", "GodotGoogleSignIn singleton init success")


func _init_apple_sign_in_plugin() -> void:
	if OS.get_name() != "iOS":
		return
	
	# AppleSignIn is typically a class provided by a plugin
	if ClassDB.class_exists("AppleSignIn"):
		_apple_sign_in_plugin = ClassDB.instantiate("AppleSignIn")
		_apple_sign_in_plugin.connect("apple_output_signal", _on_apple_login)
		App.log.info("AuthProvider", "GodotAppleSignIn singleton init success")
	else:
		App.log.warn("AuthProvider", "AppleSignIn class not found")


func _reset_vars() -> void:
	_pending_email = ""
	_apple_sign_in_nonce = ""
	_is_logging_in = false
#endregion


#region 登录流程
## 从登录弹窗触发第三方登录
func start_login() -> void:
	if is_logging_in():
		# 正在登录流程，直接返回
		return
	
	_is_logging_in = true
	if OS.get_name() == "Android":
		if _google_sign_in_plugin == null:
			on_auth_failed.emit("Google sign-in plugin not found")
			_is_logging_in = false
			return
		_google_sign_in_plugin.signInWithGoogleButton()
	elif OS.get_name() == "iOS":
		if _apple_sign_in_plugin == null:
			on_auth_failed.emit("Apple sign-in plugin not found")
			_is_logging_in = false
			return
		_apple_sign_in_plugin.sign_in()
	else:
		App.log.error("AuthProvider", "Login platform not supported")
		on_auth_failed.emit("Login platform not supported")
		_is_logging_in = false


func _on_google_sign_in_success(id_token: String, email: String, _display_name: String) -> void:
	_pending_email = email
	App.log.info("AuthProvider", "Google sign-in success: %s, %s, %s" % [id_token, email, _display_name])
	on_auth_succeeded.emit(id_token, email, "GOOGLE", {})
	_reset_vars()


func _on_google_sign_in_failed(error_message: String) -> void:
	App.log.warn("AuthProvider", "Google sign-in failed: %s" % error_message)
	_is_logging_in = false
	on_auth_failed.emit(error_message)


func _on_apple_login(id: String, email: String, name: String, token: String, error: String) -> void:
	App.log.info("AuthProvider", "Apple login: %s, %s, %s, %s, %s" % [id, email, name, token, error])
	if not error.is_empty() or token.is_empty():
		_is_logging_in = false
		on_auth_failed.emit(error if not error.is_empty() else "Apple login failed")
		return
	on_auth_succeeded.emit(id, email, "APPLE", {})
	_reset_vars()
#endregion
