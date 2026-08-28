class_name AppleAuthProvider
extends AuthProvider

## iOS Apple 原生登录 Provider (Sign in with Apple)。

var _apple_plugin: Object = null


func initialize() -> Result:
	if ClassDB.class_exists("AppleSignIn"):
		_apple_plugin = ClassDB.instantiate("AppleSignIn")
		_apple_plugin.connect("apple_output_signal", _on_apple_login)
		App.log.info("AppleAuthProvider", "Apple sign-in provider initialized")
		return Result.ok()

	App.log.warn("AppleAuthProvider", "AppleSignIn class not found")
	return Result.err("class_not_found")


func sign_in() -> void:
	if _apple_plugin == null:
		sign_in_failed.emit("Apple sign-in plugin not available")
		return
	_apple_plugin.sign_in()


func _on_apple_login(_id: String, email: String, name: String, token: String, error: String) -> void:
	if not error.is_empty() or token.is_empty():
		var err_msg := error if not error.is_empty() else "Apple login failed"
		App.log.warn("AppleAuthProvider", "Apple login error: %s" % err_msg)
		sign_in_failed.emit(err_msg)
		return

	App.log.info("AppleAuthProvider", "Apple sign-in succeeded: %s" % email)
	sign_in_succeeded.emit("apple.com", token, email, name)
