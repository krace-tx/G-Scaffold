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
	_init_scene_service()
	_phase_2_local_config_and_save()
	_phase_3_platform_sdks()
	_phase_4_remote_config()
	_phase_5_asset_preload()
	_phase_6_enter_main_menu()


## 阶段 1:日志服务。不可失败(纯本地),必须最先创建,后续阶段才能打日志。
func _phase_1_log() -> void:
	App.log = LogService.new()
	App.log.info("boot", "phase 1/6: log service ready")


## 不是 boot-sequence.md 表格里的编号阶段(那张表只列容易失败的业务初始化),
## 只是内核服务的接线步骤。挂到 App 下而不是 Boot 场景下,这样 SceneService
## 才能在 phase 6 把 Boot 场景整个替换掉之后继续存活。
func _init_scene_service() -> void:
	var scene_service := SceneService.new()
	App.add_child(scene_service)
	App.scenes = scene_service
	App.log.info("boot", "scene service ready")


## 阶段 2:本地配置 + 存档加载(含版本迁移)。失败策略:阻断,弹重试对话框。
func _phase_2_local_config_and_save() -> void:
	App.log.info("boot", "phase 2/6: local config & save — skipped (see M2)")


## 阶段 3:平台 SDK 初始化(并行,5s 超时)。失败策略:降级为 Null 实现。
func _phase_3_platform_sdks() -> void:
	App.log.info("boot", "phase 3/6: platform sdks — skipped (see M3)")


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
