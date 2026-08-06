class_name PlatformService
extends Node

## 平台能力聚合门面。
##
## 业务通过 [code]App.platform.ads[/code]、[code]App.platform.firebase_analytics[/code] 等
## 访问各能力，永远不直接触碰 SDK。详见 docs/modules/platform-service.md、ADR-0004。
##
## 初始化策略(Bootstrap 阶段 3): 各 provider **并行**初始化，各自带超时判定；
## 初始化失败或超时的，**自动降级为对应的 Null/Fallback 实现**——第三方服务故障时不影响游戏正常运行。

#region 配置常量
const _INIT_TIMEOUT: float = 15.0 ## 单个 provider 初始化的兜底超时时间（秒）
#endregion

#region 属性与状态
var firebase_analytics: FirebaseAnalyticsProvider ## Firebase 统计能力服务
var auth: AuthProvider ## 账号与登录能力服务
#endregion

#region 公开 API
## 并行初始化所有 provider，各自超时/失败降级为 Null。由 Bootstrap 阶段 3 异步 await 调用。
func setup() -> void:
	# 多个 box 用单元素数组做跨闭包可变槽: fire-and-forget 各初始化协程，让它们
	# 随帧并行推进，再统一等到所有 box 都被填上(GDScript 闭包按值捕获，值类型标记
	# 无法跨协程共享，必须用引用类型的 Array/Dictionary，详见 scene_service 内注释)。
	var fi_an_box: Array[FirebaseAnalyticsProvider] = [null]
	var au_box: Array[AuthProvider] = [null]

	# 启动并行初始化协程
	(func() -> void:
		fi_an_box[0] = await _init_or_downgrade(FirebaseAnalyticsProvider.new(), FirebaseAnalyticsProvider.new())
	).call()
	
	(func() -> void:
		au_box[0] = await _init_or_downgrade(AuthProvider.new(), AuthProvider.new())
	).call()

	# 等待所有 Provider 初始化完成或降级结束
	while fi_an_box[0] == null or au_box[0] == null:
		await get_tree().process_frame

	# 赋值给公开属性
	firebase_analytics = fi_an_box[0]
	auth = au_box[0]

	App.log.info("PlatformService", "ready (analytics=%s, auth=%s)" % [
		_provider_name(firebase_analytics),
		_provider_name(auth)
	])
#endregion

#region 内部方法
## 初始化指定的 [param provider]；成功返回它，失败(initialize 返回 false)或超时返回
## 已初始化的 [param fallback]。返回类型用 [PlatformProvider] 以复用于任意能力。
## @param provider 拟初始化的能力提供者
## @param fallback 初始化失败或超时时的降级备用实现
## @return 最终可用的 PlatformProvider 实例
func _init_or_downgrade(provider: PlatformProvider, fallback: PlatformProvider) -> PlatformProvider:
	var done: Array[bool] = [false]
	var ok: Array[bool] = [false]
	
	(func() -> void:
		# @abstract initialize 无函数体，编译器看不出它是协程而误报 await 多余；
		# 但真实现(如 SDK 初始化)是异步的，await 必须留。
		@warning_ignore("redundant_await")
		ok[0] = await provider.initialize()
		done[0] = true
	).call()

	# 轮询等待初始化完成或超时
	var elapsed := 0.0
	while not done[0] and elapsed < _INIT_TIMEOUT:
		await get_tree().process_frame
		elapsed += get_process_delta_time()

	# 初始化成功则直接返回原实例
	if done[0] and ok[0]:
		return provider

	# 失败或超时降级处理
	var reason := "failed" if done[0] else "timeout(%.0fs)" % _INIT_TIMEOUT
	App.log.warn("PlatformService", "provider init %s — downgrading to null" % reason)
	
	@warning_ignore("redundant_await") # 同上: @abstract 方法，真实现可能异步
	await fallback.initialize()
	return fallback


## 获取 provider 的 class_name（用于日志），取不到时回退到内置 get_class()。
## @param provider 能力提供者对象
## @return 类名字符串
func _provider_name(provider: PlatformProvider) -> String:
	var script := provider.get_script() as Script
	if script != null and script.get_global_name() != &"":
		return script.get_global_name()
	return provider.get_class()
#endregion
