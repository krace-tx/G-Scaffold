class_name GamePlatformStage
extends BootStage

## 第三方平台 SDK 初始化阶段。
## 顺序初始化外围平台能力（广告 / 统计 / 内购 / 登录 / 分享）。
## 采用非阻塞降级设计（Graceful Degradation）：SDK 缺失、未支持平台或初始化失败时内部降级为 Mock，记录告警但不阻断游戏正常启动。


func id() -> String:
	return "GamePlatform"


## 执行平台管理器初始化。
## 依次拉起各三方能力；无论单个 SDK 成功与否，本阶段均返回 [method Result.ok] 保证启动链路畅通。
func run(_on_progress: Callable = Callable()) -> Result:
	# 1. 广告业务（iOS ATT 授权 / AdMob 挂载）
	_guard("ad", Platform.ad.initialize())

	# 2. 统计埋点（Firebase 打点 + 本地离线上报队列）
	_guard("analytics", Platform.analytics.initialize())

	# 3. 应用内购买（异步恢复本地价格缓存 + 连接商店）
	_guard("iap", await Platform.iap.initialize())

	# 4. 第三方登录（Google / Apple 原生插件 + Firebase 换 token）
	_guard("auth", Platform.auth.initialize())

	# 5. 系统分享（原生分享插件 / Mock）
	_guard("share", Platform.share.initialize())

	info("Platform managers ready")
	return Result.ok()


## 初始化守卫：捕获并记录降级原因，防止局部 SDK 失败导致启动流程中断。
func _guard(tag: String, res: Result) -> void:
	if res.is_err():
		warn("%s init degraded: %s" % [tag, res.error])
