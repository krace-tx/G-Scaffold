class_name PlatformService
extends Node

## 平台能力聚合门面。业务通过 [code]App.platform.ads[/code]、[code]App.platform.analytics[/code]
## 访问各能力,永远不直接触碰 SDK。见 docs/modules/platform-service.md、ADR-0004。
##
## 初始化策略(Bootstrap 阶段 3):各 provider **并行**初始化,每个 5s 超时;
## 初始化失败或超时的,**自动降级为对应的 Null 实现**——第三方挂了游戏照常能玩。

#region Constants & Enums
const _INIT_TIMEOUT: float = 5.0   ## 单个 provider 初始化的兜底超时(秒)
#endregion

#region Exports & State
var ads: AdProvider              ## 广告能力(真实现或降级后的 Null)
var analytics: AnalyticsProvider ## 统计能力
#endregion

#region Public API
## 并行初始化所有 provider,各自超时/失败降级为 Null。Bootstrap 阶段 3 await 调用。
func setup() -> void:
	# 两个 box 用单元素数组做跨闭包可变槽:fire-and-forget 两个初始化协程,让它们
	# 随帧并行推进,再统一等到两个 box 都被填上(GDScript 闭包按值捕获,值类型标记
	# 无法跨协程共享,必须用引用类型的 Array/Dictionary,详见 scene_service 内注释)。
	var ad_box: Array[AdProvider] = [null]
	var an_box: Array[AnalyticsProvider] = [null]

	(func() -> void:
		ad_box[0] = await _init_or_downgrade(AdProviderFactory.create(), NullAdProvider.new())
	).call()
	(func() -> void:
		an_box[0] = await _init_or_downgrade(AnalyticsProviderFactory.create(), NullAnalyticsProvider.new())
	).call()

	while ad_box[0] == null or an_box[0] == null:
		await get_tree().process_frame

	ads = ad_box[0]
	analytics = an_box[0]
	App.log.info("platform", "ready (ads=%s, analytics=%s)" % [_provider_name(ads), _provider_name(analytics)])
#endregion

#region Internal
## 初始化 [param provider];成功返回它,失败(initialize 返回 false)或超时返回
## 已初始化的 [param fallback]。返回类型用 [PlatformProvider] 以复用于任意能力。
func _init_or_downgrade(provider: PlatformProvider, fallback: PlatformProvider) -> PlatformProvider:
	var done: Array[bool] = [false]
	var ok: Array[bool] = [false]
	(func() -> void:
		# @abstract initialize 无函数体,编译器看不出它是协程而误报 await 多余;
		# 但真实现(如 SDK 初始化)是异步的,await 必须留。
		@warning_ignore("redundant_await")
		ok[0] = await provider.initialize()
		done[0] = true
	).call()

	var elapsed := 0.0
	while not done[0] and elapsed < _INIT_TIMEOUT:
		await get_tree().process_frame
		elapsed += get_process_delta_time()

	if done[0] and ok[0]:
		return provider

	var reason := "failed" if done[0] else "timeout(%.0fs)" % _INIT_TIMEOUT
	App.log.warn("platform", "provider init %s — downgrading to null" % reason)
	@warning_ignore("redundant_await")   # 同上:@abstract 方法,真实现可能异步
	await fallback.initialize()
	return fallback


## provider 的 class_name(用于日志),取不到时回退到内置 get_class()。
func _provider_name(provider: PlatformProvider) -> String:
	var script := provider.get_script() as Script
	if script != null and script.get_global_name() != &"":
		return script.get_global_name()
	return provider.get_class()
#endregion
