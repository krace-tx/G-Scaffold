class_name Bootstrap
extends Node

## 启动管线:按固定阶段顺序初始化框架,每阶段的失败策略在此一目了然。
##
## 挂在 game/scenes/boot.tscn 的根节点上,作为项目主场景。各阶段尚未实现的
## 里程碑先记录一条日志并跳过,不阻塞后续阶段——保证 M0 阶段就能 F5 走通
## 完整管线到占位主菜单。完整设计见 docs/architecture/boot-sequence.md。

#region Lifecycle
func _ready() -> void:
	_run()
#endregion

#region Internal
func _run() -> void:
	_phase_1_log()
	_init_tree_services()
	_phase_2_local_config_and_save()
	await _phase_3_platform_sdks()   # 异步:并行初始化 provider,await 到全部就绪/降级
	await _phase_4_remote_config()   # 异步:登录 + 校时 + 拉配置握手
	_phase_5_asset_preload()
	_phase_6_enter_main_menu()


## 阶段 1:日志服务。不可失败(纯本地),必须最先创建,后续阶段才能打日志。
func _phase_1_log() -> void:
	App.log = LogService.new()
	App.log.info("boot", "phase 1/6: log service ready")


## 不是 boot-sequence.md 表格里的编号阶段(那张表只列容易失败的业务初始化),
## 只是需要常驻场景树的内核服务的接线步骤。都挂到 App 下而不是 Boot 场景下,
## 这样它们才能在 phase 6 把 Boot 场景整个替换掉之后继续存活。
func _init_tree_services() -> void:
	var scene_service := SceneService.new()
	_mount_service(scene_service, "SceneService")
	App.scenes = scene_service

	var ui_service := UIService.new()
	_mount_service(ui_service, "UIService")
	App.ui = ui_service

	var asset_service := AssetService.new()
	_mount_service(asset_service, "AssetService")
	App.assets = asset_service

	var audio_service := AudioService.new()
	_mount_service(audio_service, "AudioService")
	App.audio = audio_service

	App.log.info("boot", "scene, ui, asset & audio services ready")


## 阶段 2:时间源 + 本地配置 + 存档加载(含版本迁移)。失败策略:存档 I/O 失败
## 阻断并应弹重试对话框(占位阶段先记录 error,不真的阻断演示)。
func _phase_2_local_config_and_save() -> void:
	App.time = TimeService.new()

	App.config = ConfigService.new()
	App.config.load_local()

	App.save = SaveService.new()
	var res := App.save.load_or_create()
	if res.is_err():
		# 真实项目在此弹重试对话框(阻断);见 boot-sequence.md 阶段 2 失败策略。
		App.log.error("boot", "save load failed (would block+retry): %s" % res.error)

	App.log.info("boot", "phase 2/6: time, config & save ready")


## 阶段 3:平台 SDK 初始化(并行,5s 超时)。失败策略:降级为 Null 实现,游戏照常可玩。
func _phase_3_platform_sdks() -> void:
	var platform := PlatformService.new()
	_mount_service(platform, "PlatformService")   # Node,需在树上才能用 get_tree() 做超时轮询
	App.platform = platform
	await platform.setup()
	App.log.info("boot", "phase 3/6: platform sdks ready")


## 阶段 4:登录 + 校时 + 拉远程配置握手。失败策略:降级为本地缓存/默认值,不阻断
## (阶段 2 已 load_local,ConfigService 仍能答出上次缓存或代码默认值)。
##
## 框架本身没有真实后端,这里用 Mock 应答让 F5/CI 无头都能跑通完整链路;
## 真实项目接入后端后,把下面的 enable_mock 换成 App.net.configure(base_url, token)。
func _phase_4_remote_config() -> void:
	App.net = NetworkService.new()
	_mount_service(App.net, "NetworkService")
	App.net.enable_mock(_demo_mock_responses())

	var res := await App.net.login_and_sync()
	if res.is_err():
		App.log.warn("boot", "phase 4/6: remote config unavailable, using local cache/defaults: %s" % res.error)
	else:
		App.log.info("boot", "phase 4/6: remote config ready")


## 阶段 5:核心资产预热(常驻资产的 &"core" 组)。之后各场景的资产由 SceneService
## 在切场景时按 asset_group 预载/释放,不在此处理。
func _phase_5_asset_preload() -> void:
	App.assets.preload_group(&"core")
	App.log.info("boot", "phase 5/6: core assets preloaded")


## 阶段 6:进入主菜单场景,经 SceneService(全项目唯一允许切场景的入口)。
## SceneService.replace() 内部会先 await 转场遮罩淡出,真正调用
## change_scene_to_packed 时已经是几帧之后——不会撞上"Boot 节点自己的
## _ready 调用链尚未走完、树还在忙着添加子节点"这个坑,不需要 call_deferred。
func _phase_6_enter_main_menu() -> void:
	App.log.info("boot", "phase 6/6: entering main menu")
	App.scenes.replace(Scenes.MAIN_MENU)


## 把一个常驻服务节点挂到 App 下,并按 [param node_name] 命名(让调试场景树可读:
## App/SceneService 而不是 App/@Node@2)。走 NodeUtils.mount_required——统一守卫,
## 失败即接线 bug 由其 push_error 大声报出,不在此重复处理。
func _mount_service(node: Node, node_name: String) -> void:
	NodeUtils.mount_required(node, App, node_name)


## 框架自带的演示用 Mock 应答表(path → 响应体),仅用于让 Bootstrap 在没有真实
## 后端时也能演示完整链路。真实项目替换阶段 4 的接线后,这个方法可以删除。
func _demo_mock_responses() -> Dictionary:
	return {
		"/auth/login": {
			"token": "demo-token",
			"server_time_msec": int(Time.get_unix_time_from_system() * 1000.0),
		},
		"/config/remote": {"maintenance": false},
	}
#endregion
