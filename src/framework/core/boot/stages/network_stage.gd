class_name NetworkStage
extends BootStage

## 阶段 4:登录 + 校时 + 远程配置握手。无真实后端时用 Mock 演示完整链路。

#region Public API
func get_name() -> String:
	return "Network"


func failure_strategy() -> BootFailureStrategy.Kind:
	return BootFailureStrategy.Kind.DEGRADE


func run(_ctx: BootContext) -> Result:
	App.net = NetworkService.new()
	NodeUtils.mount_required(App.net, App, "NetworkService")
	App.net.enable_mock(_demo_mock_responses())

	var res: Result = await App.net.login_and_sync()
	if res.is_err():
		return res

	App.log.info(LOG_TAG, "remote config ready")
	return Result.ok()
#endregion

#region Internal
# 框架演示用 Mock 应答;接入真实后端后删除,改在 Stage 内调用 App.net.configure()。
func _demo_mock_responses() -> Dictionary:
	return {
		"/auth/login": {
			"token": "demo-token",
			"server_time_msec": int(Time.get_unix_time_from_system() * 1000.0),
		},
		"/config/remote": {"maintenance": false},
	}
#endregion
