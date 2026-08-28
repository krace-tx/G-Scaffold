class_name AuthPipeline
extends RefCounted

## 认证登录调度流水线。
## 协调各渠道 AuthProvider 授权 ➔ Firebase/自研 Token 换取 ➔ 构造 AuthUser 实体的标准生命周期。

signal auth_succeeded(user: AuthUser)
signal auth_failed(error_message: String)

var _google_provider := GoogleAuthProvider.new()
var _apple_provider := AppleAuthProvider.new()
var _mock_provider := MockAuthProvider.new()
var _token_client := FirebaseTokenClient.new()


func initialize() -> Result:
	if App.env.is_android():
		var res := _google_provider.initialize()
		if res.is_err():
			_mock_provider.initialize()
	elif App.env.is_ios():
		var res := _apple_provider.initialize()
		if res.is_err():
			_mock_provider.initialize()
	else:
		_mock_provider.initialize()

	App.log.info("AuthPipeline", "Auth pipeline initialized")
	return Result.ok()


## 执行异步登录流水线。
func login_async(channel: int = AuthChannel.AUTO) -> Result:
	var provider := _resolve_provider(channel)
	if provider == null:
		var err := "No available auth provider for channel: %d" % channel
		auth_failed.emit(err)
		return Result.err(err)

	# 1. 临时绑定单次登录事件监听
	var success_data := []
	var error_data := []

	var on_success: Callable
	var on_failed: Callable

	on_success = func(p_id: String, p_token: String, p_email: String, _p_name: String):
		success_data.append({ "provider_id": p_id, "token": p_token, "email": p_email })

	on_failed = func(err_msg: String):
		error_data.append(err_msg)

	provider.sign_in_succeeded.connect(on_success, CONNECT_ONE_SHOT)
	provider.sign_in_failed.connect(on_failed, CONNECT_ONE_SHOT)

	# 2. 触发原生登录
	provider.sign_in()

	# 3. 等待原生授权结果
	while success_data.is_empty() and error_data.is_empty():
		await App.get_tree().process_frame

	# 4. 处理原生失败
	if not error_data.is_empty():
		var err_msg: String = error_data[0]
		App.log.warn("AuthPipeline", "Provider sign-in failed: %s" % err_msg)
		auth_failed.emit(err_msg)
		return Result.err(err_msg)

	# 5. 原生授权成功，发起 Token 兑换
	var raw_auth: Dictionary = success_data[0]
	var provider_id: String = raw_auth["provider_id"]
	var token: String = raw_auth["token"]
	var email: String = raw_auth["email"]

	App.log.info("AuthPipeline", "Provider sign-in succeeded, exchanging token...")
	var exchange_res: Result = await _token_client.exchange_token(provider_id, token)

	if exchange_res.is_err():
		var err_msg := "Token exchange failed: %s" % str(exchange_res.error)
		App.log.error("AuthPipeline", err_msg)
		auth_failed.emit(err_msg)
		return Result.err(err_msg)

	# 6. 构建不可变领域实体 AuthUser
	var data := exchange_res.value as Dictionary
	var uid := str(data.get("localId", ""))
	var final_email := str(data.get("email", email))
	var source := "APPLE" if provider_id == "apple.com" else ("GOOGLE" if provider_id == "google.com" else "MOCK")

	var user := AuthUser.create(uid, final_email, source, data)
	App.log.info("AuthPipeline", "Login succeeded for UID: %s" % uid)
	auth_succeeded.emit(user)
	return Result.ok(user)


## 触发登出注销。
func sign_out(channel: int = AuthChannel.AUTO) -> void:
	var provider := _resolve_provider(channel)
	if provider != null:
		provider.sign_out()


func _resolve_provider(channel: int) -> AuthProvider:
	match channel:
		AuthChannel.GOOGLE:
			if App.env.is_android():
				return _google_provider
			return _mock_provider
		AuthChannel.APPLE:
			if App.env.is_ios():
				return _apple_provider
			return _mock_provider
		AuthChannel.MOCK:
			return _mock_provider
		AuthChannel.AUTO:
			if App.env.is_android():
				return _google_provider
			elif App.env.is_ios():
				return _apple_provider
			else:
				return _mock_provider
		_:
			return _mock_provider
