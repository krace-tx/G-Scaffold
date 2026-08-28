class_name AuthClient
extends RefCounted

## 认证登录子系统统一入口门面 (Platform.auth)。
## 采用驱动与流水线架构，统一提供基于 [method login_async] 的异步登录流程与全局状态管理。

signal auth_succeeded(user: AuthUser)
signal auth_failed(error_message: String)
signal logged_out()

var _pipeline := AuthPipeline.new()
var _current_user: AuthUser = null
var _is_logging_in := false


#region Lifecycle
func initialize() -> Result:
	_pipeline.auth_succeeded.connect(func(user: AuthUser):
		_current_user = user
		_is_logging_in = false
		auth_succeeded.emit(user)
	)
	_pipeline.auth_failed.connect(func(err: String):
		_is_logging_in = false
		auth_failed.emit(err)
	)

	var res := _pipeline.initialize()
	App.log.info("AuthClient", "Auth subsystem ready")
	return res
#endregion


#region Public API
## 当前是否正在进行登录流程中。
func is_logging_in() -> bool:
	return _is_logging_in


## 是否已登录成功。
func is_logged_in() -> bool:
	return _current_user != null and not _current_user.uid.is_empty()


## 获取当前已登录的用户信息实体；未登录返回 null。
func current_user() -> AuthUser:
	return _current_user


## 异步发起登录流程并等待最终结果。
## [param channel] 登录渠道，默认 [code]AuthChannel.AUTO[/code]（自动匹配当前平台）。
## 成功返回包含 [AuthUser] 的 [method Result.ok]，失败返回带原因的 [method Result.err]。
func login_async(channel: int = AuthChannel.AUTO) -> Result:
	if _is_logging_in:
		App.log.warn("AuthClient", "Login already in progress, ignore request")
		return Result.err("already_in_progress")

	_is_logging_in = true
	App.log.info("AuthClient", "Starting login flow (channel: %d)" % channel)
	return await _pipeline.login_async(channel)


## 以信号触发模式发起登录（兼顾非 await 场景）。
func start_login(channel: int = AuthChannel.AUTO) -> void:
	login_async(channel)


## 退出当前登录账号并重置认证状态。
## [param channel] 对应渠道，默认 [code]AuthChannel.AUTO[/code]。
func logout(channel: int = AuthChannel.AUTO) -> void:
	_current_user = null
	_is_logging_in = false
	_pipeline.sign_out(channel)
	App.log.info("AuthClient", "User logged out successfully")
	logged_out.emit()
#endregion
