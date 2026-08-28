extends Node
## 全局服务聚合根 (Autoload / Service Locator)
## 统一持有各子系统的强类型引用，提供全局访问点。
## 接管并分发 OS 层面的生命周期与系统级事件。

#region Core Services
var env:		EnvironmentService	## 基础：运行环境 (Local/Emulator/Dev/Test/Prod)
@warning_ignore("shadowed_global_identifier")
var log:		LogService			## 基础：日志与诊断
var net:		NetworkService		## 通讯：HTTP连接池、断线重连、Token鉴权
var persist:	PersistService		## 存储：本地/云端数据持久化
var time:		TimeService			## 校验：服务器权威时间校准
var locale:		LocaleService		## 表现：多语言与区域格式化
var asset:		AssetService		## 资源：资产加载池、内存/磁盘缓存管理
var scene:		SceneService		## 表现：场景流转与转场遮罩
var audio:		AudioService		## 表现：音效分组与交叉淡变
#endregion

#region Bootstrap
var _boot_done := false
var _booting := false
var _is_app_paused := false


## 跑默认 [BootPipeline]。[method _ready] 会调一次；别处 [code]await App.bootstrap()[/code] 等到结束。已完成则跳过。
func bootstrap() -> void:
	if _boot_done:
		return
	if _booting:
		while _booting:
			await get_tree().process_frame
		return
	_booting = true
	await BootPipeline.new(BootPipeline.app_launch_stages()).run()
	_boot_done = true
	_booting = false
#endregion

#region System Lifecycle
func _ready() -> void:
	# 禁用引擎的“收到退出信号立刻强制关闭”行为，交由 _on_app_quit 统一处理
	get_tree().set_auto_accept_quit(false)
	await bootstrap()


func _notification(what: int) -> void:
	match what:
		# 1. 移动端：挂起与恢复
		NOTIFICATION_APPLICATION_PAUSED:  _on_app_paused()
		NOTIFICATION_APPLICATION_RESUMED: _on_app_resumed()
		
		# 2. PC端：窗口焦点切换
		NOTIFICATION_WM_WINDOW_FOCUS_OUT: _on_app_focus_out()
		NOTIFICATION_WM_WINDOW_FOCUS_IN:  _on_app_focus_in()
		
		# 3. 硬件交互：物理返回键 / ESC
		NOTIFICATION_WM_GO_BACK_REQUEST:  _on_app_go_back()
		
		# 4. 系统管控：优雅退出与内存警告
		NOTIFICATION_WM_CLOSE_REQUEST:    _on_app_quit()
		NOTIFICATION_OS_MEMORY_WARNING:   _on_app_low_memory()
#endregion

#region Internal Event Handlers
## 切后台：落盘存档并广播 Bus.app_paused。
func _on_app_paused() -> void:
	if _is_app_paused:
		return
	_is_app_paused = true
	log.info("app", "App paused.")
	Bus.app_paused.emit()


## 回前台：异步重同步，并立即广播 Bus.app_resumed。
func _on_app_resumed() -> void:
	if not _is_app_paused:
		return
	_is_app_paused = false
	log.info("app", "App resumed.")
	Bus.app_resumed.emit()


## 窗口失焦（PC/桌面端）：暂停音频并触发 App 挂起逻辑。
func _on_app_focus_out() -> void:
	log.info("app", "App focus out.")
	audio.set_paused(true)
	_on_app_paused()


## 窗口获焦（PC/桌面端）：恢复音频并触发 App 恢复逻辑。
func _on_app_focus_in() -> void:
	log.info("app", "App focus in.")
	audio.set_paused(false)
	_on_app_resumed()


## 返回键 / ESC / 侧滑返回：广播 Bus.app_back_pressed，由当前前台 UI 或场景监听消费。
func _on_app_go_back() -> void:
	log.info("app", "App back pressed.")
	Bus.app_back_pressed.emit()


## 关闭请求：flush 后允许退出（auto_accept_quit 已关闭）。
func _on_app_quit() -> void:
	log.info("app", "App quit.")
	get_tree().quit()


## 系统内存警告：释放缓存与非必要资源。
func _on_app_low_memory() -> void:
	log.warn("app", "App low memory")

#endregion
