extends Node

## 全局服务聚合根(Autoload)。
##
## 持有全部框架服务的类型化引用(`App.log`、`App.scenes`……),由 [Bootstrap]
## 按阶段顺序创建并赋值,不依赖 Autoload 加载顺序。全项目只有 [App] 与 [Bus]
## 两个 Autoload,禁止新增,详见 docs/architecture/decisions/0001-typed-app-root.md。
##
## 字段随里程碑逐个补充:一个服务类还不存在时,不能声明它的类型化字段
## (GDScript 无法引用不存在的类),所以本文件只在服务落地那个里程碑里追加对应行。
##
## 同时接管应用生命周期通知(切后台/恢复/返回键),转发为 [Bus] 领域事件。
## 详见 docs/architecture/boot-sequence.md 应用生命周期一节。

#region Exports & State
## `log` 与内置全局函数 log()(自然对数)同名,此处刻意遮蔽:
## `App.log` 这个命名在全项目统一且更常用,不会被误认成数学函数。
@warning_ignore("shadowed_global_identifier")
## [初始化 01/12] 基础日志与诊断服务（最优先创建，后续所有服务均依赖其记录日志）
var log: LogService

## [初始化 02/12] 运行环境服务（识别当前游戏环境：Local / Dev / Prod）
var env: EnvironmentService

## [初始化 03/12] 网络传输服务（HTTP 连接池、失败重试、Token 鉴权与 Mock 模式）
var net: NetworkService

## [初始化 04/12] 数据持久化服务（提供内存 / 磁盘 / 网络的统一存取接口）
var persist: PersistService

## [初始化 05/12] 图片缓存服务（远程图片的内存/磁盘缓存与下载，基于 PersistService + NetworkService）
var image_cache: ImageCacheService

## [初始化 06/12] 权威时间源服务（服务器网络校时与同步，未完成校时前不可信）
var time: TimeService

## [初始化 07/12] 本地化服务（多语言文本翻译、区域格式控制与语言切换）
var locale: LocaleService

## [初始化 08/12] 资源管理服务（基于 asset_map 的分组预载、加载与动态释放）
var assets: AssetService

## [初始化 09/12] 场景流转服务（管理场景切换、生命周期契约及转场遮罩）
var scenes: SceneService

## [初始化 10/12] Perfab 框架服务（视图加载、缓存服务）
var prefab: PrefabService

## [初始化 11/12] 音频系统服务（BGM/SFX 音量分组、交叉淡变与 AudioStreamPlayer 池）
var audio: AudioService

## [初始化 12/12] 平台能力门面（统一接入第三方/平台 SDK，如 App.platform.ads / .analytics）
var platform: PlatformService
#endregion

#region Lifecycle
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			_on_app_paused()
		NOTIFICATION_APPLICATION_RESUMED:
			_on_app_resumed()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_on_go_back()
#endregion

#region Internal
func _on_app_paused() -> void:
	if log: log.info("app", "application paused")
	# 切后台是 iOS 上唯一可靠的保存时机,务必 flush 存档。
	#if save: save.flush()
	Bus.app_paused.emit()


func _on_app_resumed() -> void:
	if log: log.info("app", "application resumed")
	# 恢复时重新握手:校时可能已过期(挂后台太久),远程配置也可能已变。
	# fire-and-forget:不阻塞 _notification 处理,失败只记日志、不影响恢复流程。
	if net:
		(func() -> void:
			var res: Result = await net.login_and_sync()
			if res.is_err():
				log.warn("app", "resume re-sync failed: %s" % res.error)
		).call()
	Bus.app_resumed.emit()


## Android 返回键:先给 UI 栈处理(关栈顶弹窗);UI 没消费再走场景级返回。
func _on_go_back() -> void:
	# TODO(后续):无弹窗时的场景级返回 / 主菜单退出确认(见 boot-sequence.md)。
	if log: log.info("app", "back not consumed by ui — scene-level back is TODO")
#endregion
