class_name GoogleAuthProvider
extends AuthProvider

## Android Google 原生登录 Provider。

var _google_plugin = null


func initialize() -> Result:
	if not Engine.has_singleton("GodotGoogleSignIn"):
		App.log.warn("GoogleAuthProvider", "GodotGoogleSignIn singleton not found")
		return Result.err("singleton_not_found")

	_google_plugin = Engine.get_singleton("GodotGoogleSignIn")
	_google_plugin.initialize(PlatformCatalog.GOOGLE_WEB_CLIENT_ID)
	if _google_plugin.has_signal("sign_in_success"):
		_google_plugin.connect("sign_in_success", _on_sign_in_success)
	if _google_plugin.has_signal("sign_in_failed"):
		_google_plugin.connect("sign_in_failed", _on_sign_in_failed)

	App.log.info("GoogleAuthProvider", "Google sign-in provider initialized")
	return Result.ok()


func sign_in() -> void:
	if _google_plugin == null:
		sign_in_failed.emit("Google sign-in plugin not available")
		return
	_google_plugin.signInWithGoogleButton()


func sign_out() -> void:
	if _google_plugin != null and _google_plugin.has_method("signOut"):
		_google_plugin.signOut()
		App.log.info("GoogleAuthProvider", "Google sign-out executed")


func _on_sign_in_success(id_token: String, email: String, display_name: String) -> void:
	App.log.info("GoogleAuthProvider", "Google sign-in succeeded: %s" % email)
	sign_in_succeeded.emit("google.com", id_token, email, display_name)


func _on_sign_in_failed(error_message: String) -> void:
	App.log.warn("GoogleAuthProvider", "Google sign-in failed: %s" % error_message)
	sign_in_failed.emit(error_message)
