class_name CoreServiceStage
extends BootStage

## 常驻场景树服务接线:Scene / UI / Asset / Audio。
##
## 不是 boot-sequence 表格里的编号阶段,而是切场景后仍需存活的内核服务;
## 全部挂到 App 下而非 Boot 场景下。

#region Public API
func get_name() -> String:
	return "CoreService"


func failure_strategy() -> BootFailureStrategy.Kind:
	return BootFailureStrategy.Kind.FATAL


func run(_ctx: BootContext) -> Result:
	# [初始化 01/12] 日志服务：必须最先创建，后续所有服务的日志记录均依赖它
	App.log = LogService.new()
	App.log.info(LOG_TAG, "Log service ready.")
	
	# [初始化 02/12] 环境服务：识别当前游戏环境（本地/开发/生产），决定 API 域名等后续配置
	App.env = EnvironmentService.new()
	App.log.info(LOG_TAG, "Environment service ready.")
	
	# [初始化 03/12] 网络服务：传输层（HTTP 池 + 重试 + 鉴权 模式）；Node 型服务需挂树
	App.net = NetworkService.new()
	NodeUtils.mount_required(App.net, App, "NetworkService")
	App.log.info(LOG_TAG, "Network service ready.")

	# [初始化 04/12] 持久化服务：统一存取（内存/磁盘/网络）；locale 等后续服务依赖它读取设置
	App.persist = PersistService.new()
	App.log.info(LOG_TAG, "Persist service ready.")

	# [初始化 05/12] 图片缓存服务：远程图片的内存/磁盘缓存与下载；依赖 persist（内存池）与 net（下载）
	App.image_cache = ImageCacheService.new()
	App.log.info(LOG_TAG, "Image cache service ready.")

	# [初始化 06/12] 时间服务：权威时间源（未与服务端同步校时前不可信）
	App.time = TimeService.new()
	App.log.info(LOG_TAG, "Time service ready.")
	
	# [初始化 07/12] 本地化服务：多语言与区域格式；依赖 persist 读取已保存的语言设置
	App.locale = LocaleService.new()
	App.log.info(LOG_TAG, "Locale service ready.")
	
	# [初始化 08/12] 资源服务：基于 asset group 进行按组预载与释放；Node 型服务需挂树
	App.assets = AssetService.new()
	NodeUtils.mount_required(App.assets, App, "AssetService")
	App.log.info(LOG_TAG, "Asset service ready.")
	
	# [初始化 09/12] 场景服务：场景切换与生命周期管理；挂载至 App 下以在切场景后存活
	App.scenes = SceneService.new()
	NodeUtils.mount_required(App.scenes, App, "SceneService")
	App.log.info(LOG_TAG, "Scene service ready.")

	# [初始化 10/12] UI 服务：界面栈与弹窗路由管理；挂载至 App 下以在切场景后存活
	App.prefab = PrefabService.new()
	NodeUtils.mount_required(App.prefab, App, "PrefabService")
	App.log.info(LOG_TAG, "UI service ready.")

	# [初始化 11/12] 音频服务：BGM/SFX 音量分组 + 交叉淡变 + 播放器池；Node 型服务需挂树
	App.audio = AudioService.new()
	NodeUtils.mount_required(App.audio, App, "AudioService")
	App.log.info(LOG_TAG, "Audio service ready.")
	
	# [初始化 12/12] 平台服务：平台能力门面（App.platform.ads / .analytics）；Node 型服务需挂树并 await setup
	App.platform = PlatformService.new()
	NodeUtils.mount_required(App.platform, App, "PlatformService")
	await App.platform.setup()
	App.log.info(LOG_TAG, "Platform service ready.")

	return Result.ok()
#endregion
