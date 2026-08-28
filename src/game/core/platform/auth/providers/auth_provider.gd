class_name AuthProvider
extends RefCounted

## 三方登录 Provider 抽象基类。

@warning_ignore("unused_signal")
signal sign_in_succeeded(provider_id: String, token: String, email: String, display_name: String)
@warning_ignore("unused_signal")
signal sign_in_failed(error_message: String)


func initialize() -> Result:
	return Result.ok()


func sign_in() -> void:
	pass


func sign_out() -> void:
	pass
