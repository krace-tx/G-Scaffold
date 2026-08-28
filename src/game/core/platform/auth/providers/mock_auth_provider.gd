class_name MockAuthProvider
extends AuthProvider

## Mock 登录 Provider（PC / 编辑器 / 不支持平台联调）。


func initialize() -> Result:
	App.log.info("MockAuthProvider", "Mock auth provider initialized")
	return Result.ok()


func sign_in() -> void:
	App.log.info("MockAuthProvider", "Mock login triggered")
	(func() -> void:
		await App.get_tree().create_timer(0.3).timeout
		sign_in_succeeded.emit("mock.com", "mock_oauth_token", "mock_user@example.com", "Mock User")
	).call()
