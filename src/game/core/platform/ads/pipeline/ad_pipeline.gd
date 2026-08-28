class_name AdPipeline
extends RefCounted

## 广告调度流水线。
## 协调 iOS ATT 授权流程、底层 AdMob/Mock 驱动激活，并调度广告的预加载与展示。

var _att := AttController.new()
var _driver: AdDriver = null


#region Lifecycle
func initialize() -> Result:
	# 1. 桌面端 / 编辑器环境：降级为 Mock 驱动
	if not App.env.is_mobile():
		_driver = MockAdDriver.new()
		return _driver.initialize()

	# 2. 移动端环境：实例化 AdMob 原生驱动
	_driver = AdMobDriver.new()

	# 3. iOS 专属流程：检查 ATT 授权状态，若未请求过则先弹窗，用户响应后再异步初始化 AdMob
	if App.env.is_ios():
		_att.load_state()
		if not _att.is_requested():
			_att.permission_completed.connect(func(_status: Dictionary):
				_driver.initialize()
			)
			_att.request_permission()
			App.log.info("AdPipeline", "ATT permission requested, awaiting result before init AdMob")
			return Result.ok()
		App.log.info("AdPipeline", "ATT already requested, init AdMob directly")

	# 4. Android 平台（或 iOS 已完成 ATT 授权）：直接初始化 AdMob SDK
	return _driver.initialize()
#endregion


#region Rewarded Ads
func is_rewarded_ready() -> bool:
	return _driver.is_rewarded_ready() if _driver != null else false


func load_rewarded() -> void:
	if _driver != null:
		_driver.load_rewarded()


func show_rewarded() -> Result:
	if _driver == null:
		return Result.err("ad_not_initialized")
	return await _driver.show_rewarded()
#endregion


#region Interstitial Ads
func is_interstitial_ready() -> bool:
	return _driver.is_interstitial_ready() if _driver != null else false


func load_interstitial() -> void:
	if _driver != null:
		_driver.load_interstitial()


func show_interstitial() -> Result:
	if _driver == null:
		return Result.err("ad_not_initialized")
	return await _driver.show_interstitial()
#endregion


#region Banner Ads
func load_banner() -> void:
	if _driver != null:
		_driver.load_banner()


func show_banner() -> void:
	if _driver != null:
		_driver.show_banner()


func hide_banner() -> void:
	if _driver != null:
		_driver.hide_banner()
#endregion
