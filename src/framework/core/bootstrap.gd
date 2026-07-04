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
	_init_ui_and_scene_services()
	_phase_2_local_config_and_save()
	await _phase_3_platform_sdks()   # 异步:并行初始化 provider,await 到全部就绪/降级
	_phase_4_remote_config()
	_phase_5_asset_preload()
	_phase_6_enter_main_menu()


## 阶段 1:日志服务。不可失败(纯本地),必须最先创建,后续阶段才能打日志。
func _phase_1_log() -> void:
	App.log = LogService.new()
	App.log.info("boot", "phase 1/6: log service ready")


## 不是 boot-sequence.md 表格里的编号阶段(那张表只列容易失败的业务初始化),
## 只是内核服务的接线步骤。都挂到 App 下而不是 Boot 场景下,这样它们才能在
## phase 6 把 Boot 场景整个替换掉之后继续存活。
func _init_ui_and_scene_services() -> void:
	var scene_service := SceneService.new()
	App.add_child(scene_service)
	App.scenes = scene_service

	var ui_service := UIService.new()
	App.add_child(ui_service)
	App.ui = ui_service

	App.log.info("boot", "scene & ui services ready")


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
	App.add_child(platform)   # Node,需在树上才能用 get_tree() 做超时轮询
	App.platform = platform
	await platform.setup()
	App.log.info("boot", "phase 3/6: platform sdks ready")


## 阶段 4:远程配置拉取(3s 超时)。失败策略:降级为本地缓存/默认值。
func _phase_4_remote_config() -> void:
	App.log.info("boot", "phase 4/6: remote config — skipped (see M4)")


## 阶段 5:核心资产预热。失败策略:阻断,重试。
func _phase_5_asset_preload() -> void:
	App.log.info("boot", "phase 5/6: asset preload — skipped (see M5)")


## 阶段 6:进入主菜单场景,经 SceneService(全项目唯一允许切场景的入口)。
## SceneService.replace() 内部会先 await 转场遮罩淡出,真正调用
## change_scene_to_packed 时已经是几帧之后——不会撞上"Boot 节点自己的
## _ready 调用链尚未走完、树还在忙着添加子节点"这个坑,不需要 call_deferred。
func _phase_6_enter_main_menu() -> void:
	App.log.info("boot", "phase 6/6: entering main menu")
	App.scenes.replace(SceneIds.MAIN_MENU)
#endregion
