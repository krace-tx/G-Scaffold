class_name CoreServiceStage
extends BootStage

## 按依赖顺序创建框架常驻服务并挂到 App。失败则无法进入游戏。

func id() -> String:
	return "CoreService"


func run(_on_progress: Callable = Callable()) -> Result:
	# env 先于 log：创建日志时按环境定 min_level。此前 BootStage 日志走 print。
	App.env = EnvironmentService.new()
	info("Environment service ready (%s)." % App.env.get_name())

	App.log = LogService.new(App.env)
	info("Logger service ready (min_level=%s)." % LogService.LogLevel.keys()[App.log.min_level])

	# Node 型服务挂 App 下，切走 Boot 场景后仍存活。
	App.net = NetworkService.new()
	NodeUtils.mount_required(App.net, App, "NetworkService")
	info("Network service ready.")

	App.persist = PersistService.new()
	info("Persist service ready.")

	App.time = TimeService.new()
	info("Time service ready.")

	App.locale = LocaleService.new()
	var locale_res := App.locale.initialize()
	if locale_res.is_err():
		return locale_res
	info("Locale service ready.")

	App.asset = AssetService.new()
	NodeUtils.mount_required(App.asset, App, "AssetService")
	info("Asset service ready.")

	App.scene = SceneService.new()
	NodeUtils.mount_required(App.scene, App, "SceneService")
	info("Scene service ready.")

	App.audio = AudioService.new()
	NodeUtils.mount_required(App.audio, App, "AudioService")
	info("Audio service ready.")

	return Result.ok()
