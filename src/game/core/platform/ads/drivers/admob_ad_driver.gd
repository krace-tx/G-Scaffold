class_name AdMobDriver
extends AdDriver

## Google AdMob 广告原生驱动。
## 封装激励视频、插屏与横幅广告的异步加载、展示、安全重试与事件回调监听。

#region State
# 激励视频
var _rewarded_ad: RewardedAd = null
var _rewarded_loading := false
var _rewarded_retry := -1
var _reward_earned := false

# 插屏
var _interstitial_ad: InterstitialAd = null
var _interstitial_loading := false
var _interstitial_retry := -1

# Banner
var _banner_ad: AdView = null
var _banner_loading := false
var _banner_retry := -1
var _banner_show_requested := false
#endregion

#region Internal Signals
signal _rewarded_finished(result: Result)
signal _interstitial_finished(result: Result)
#endregion


#region Lifecycle
func initialize() -> Result:
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = _on_initialization_complete
	MobileAds.initialize(listener)
	App.log.info("AdMobDriver", "AdMob initialization triggered")
	return Result.ok()


func _on_initialization_complete(status: InitializationStatus) -> void:
	for adapter_name in status.adapter_status_map.keys():
		var adapter_status = status.adapter_status_map[adapter_name]
		App.log.info("AdMobDriver", "Adapter: %s, state: %s, desc: %s" % [
			adapter_name,
			adapter_status.initialization_state,
			adapter_status.description,
		])
#endregion


#region Rewarded Ads
func is_rewarded_ready() -> bool:
	return _rewarded_ad != null


func load_rewarded() -> void:
	if _rewarded_loading or _rewarded_ad != null:
		return
	_rewarded_loading = true

	var unit_id := _rewarded_unit_id()
	var callback := RewardedAdLoadCallback.new()
	callback.on_ad_loaded = _on_rewarded_ad_loaded
	callback.on_ad_failed_to_load = _on_rewarded_ad_failed_to_load

	var request := AdRequest.new()
	RewardedAdLoader.new().load(unit_id, request, callback)
	App.log.info("AdMobDriver", "Loading rewarded ad (unit_id='%s')" % unit_id)


func show_rewarded() -> Result:
	if _rewarded_ad == null:
		App.log.warn("AdMobDriver", "Rewarded ad is not ready, triggering load")
		load_rewarded()
		return Result.err("ad_not_ready")

	_reward_earned = false

	var listener := OnUserEarnedRewardListener.new()
	listener.on_user_earned_reward = func(_item: RewardedItem):
		_reward_earned = true
		App.log.info("AdMobDriver", "User earned reward callback received")

	_rewarded_ad.show(listener)

	var res: Result = await _rewarded_finished
	_rewarded_ad.destroy()
	_rewarded_ad = null
	load_rewarded()

	return res


func _on_rewarded_ad_loaded(ad: RewardedAd) -> void:
	_rewarded_ad = ad
	_rewarded_loading = false
	_rewarded_retry = -1

	var callback := FullScreenContentCallback.new()
	callback.on_ad_clicked = func(): App.log.debug("AdMobDriver", "Rewarded ad clicked")
	callback.on_ad_dismissed_full_screen_content = func():
		App.log.info("AdMobDriver", "Rewarded ad dismissed (earned=%s)" % _reward_earned)
		if _reward_earned:
			_rewarded_finished.emit(Result.ok())
		else:
			_rewarded_finished.emit(Result.err("reward_not_earned"))

	callback.on_ad_failed_to_show_full_screen_content = func(ad_error: AdError):
		App.log.error("AdMobDriver", "Rewarded ad failed to show: %s" % ad_error.message)
		_rewarded_finished.emit(Result.err(ad_error.message))

	callback.on_ad_impression = func(): App.log.debug("AdMobDriver", "Rewarded ad impression recorded")
	callback.on_ad_showed_full_screen_content = func(): App.log.debug("AdMobDriver", "Rewarded ad showed full screen")

	_rewarded_ad.full_screen_content_callback = callback
	App.log.info("AdMobDriver", "Rewarded ad loaded successfully")


func _on_rewarded_ad_failed_to_load(load_ad_error: LoadAdError) -> void:
	_rewarded_ad = null
	_rewarded_loading = false
	App.log.warn("AdMobDriver", "Rewarded ad failed to load: %s" % load_ad_error.message)
	_retry_load_rewarded()


func _retry_load_rewarded() -> void:
	_rewarded_retry = mini(_rewarded_retry + 1, 3)
	var delays: Array[float] = [1.0, 3.0, 5.0, 10.0]
	var delay: float = delays[_rewarded_retry]
	App.log.info("AdMobDriver", "Retry loading rewarded ad in %.1fs (attempt %d)" % [delay, _rewarded_retry + 1])
	await TimeUtils.wait_safe(App, delay)
	load_rewarded()
#endregion


#region Interstitial Ads
func is_interstitial_ready() -> bool:
	return _interstitial_ad != null


func load_interstitial() -> void:
	if _interstitial_loading or _interstitial_ad != null:
		return
	_interstitial_loading = true

	var unit_id := _interstitial_unit_id()
	var callback := InterstitialAdLoadCallback.new()
	callback.on_ad_loaded = _on_interstitial_ad_loaded
	callback.on_ad_failed_to_load = _on_interstitial_ad_failed_to_load

	var request := AdRequest.new()
	InterstitialAdLoader.new().load(unit_id, request, callback)
	App.log.info("AdMobDriver", "Loading interstitial ad (unit_id='%s')" % unit_id)


func show_interstitial() -> Result:
	if _interstitial_ad == null:
		App.log.warn("AdMobDriver", "Interstitial ad is not ready, triggering load")
		load_interstitial()
		return Result.err("ad_not_ready")

	_interstitial_ad.show()

	var res: Result = await _interstitial_finished
	_interstitial_ad.destroy()
	_interstitial_ad = null
	load_interstitial()

	return res


func _on_interstitial_ad_loaded(ad: InterstitialAd) -> void:
	_interstitial_ad = ad
	_interstitial_loading = false
	_interstitial_retry = -1

	var callback := FullScreenContentCallback.new()
	callback.on_ad_clicked = func(): App.log.debug("AdMobDriver", "Interstitial ad clicked")
	callback.on_ad_dismissed_full_screen_content = func():
		App.log.info("AdMobDriver", "Interstitial ad dismissed")
		_interstitial_finished.emit(Result.ok())

	callback.on_ad_failed_to_show_full_screen_content = func(ad_error: AdError):
		App.log.error("AdMobDriver", "Interstitial ad failed to show: %s" % ad_error.message)
		_interstitial_finished.emit(Result.err(ad_error.message))

	callback.on_ad_impression = func(): App.log.debug("AdMobDriver", "Interstitial ad impression recorded")
	callback.on_ad_showed_full_screen_content = func(): App.log.debug("AdMobDriver", "Interstitial ad showed full screen")

	_interstitial_ad.full_screen_content_callback = callback
	App.log.info("AdMobDriver", "Interstitial ad loaded successfully")


func _on_interstitial_ad_failed_to_load(load_ad_error: LoadAdError) -> void:
	_interstitial_ad = null
	_interstitial_loading = false
	App.log.warn("AdMobDriver", "Interstitial ad failed to load: %s" % load_ad_error.message)
	_retry_load_interstitial()


func _retry_load_interstitial() -> void:
	_interstitial_retry = mini(_interstitial_retry + 1, 3)
	var delays: Array[float] = [1.0, 3.0, 5.0, 10.0]
	var delay: float = delays[_interstitial_retry]
	App.log.info("AdMobDriver", "Retry loading interstitial ad in %.1fs (attempt %d)" % [delay, _interstitial_retry + 1])
	await TimeUtils.wait_safe(App, delay)
	load_interstitial()
#endregion


#region Banner Ads
func load_banner() -> void:
	if _banner_loading or _banner_ad != null:
		return
	_banner_loading = true

	var unit_id := _banner_unit_id()
	_banner_ad = AdView.new(unit_id, AdSize.BANNER, AdPosition.Values.BOTTOM)
	_banner_ad.ad_listener = _create_banner_listener()

	var request := AdRequest.new()
	_banner_ad.load_ad(request)
	App.log.info("AdMobDriver", "Loading banner ad (unit_id='%s')" % unit_id)


func show_banner() -> void:
	_banner_show_requested = true
	if _banner_ad != null:
		_banner_ad.show()
	else:
		load_banner()


func hide_banner() -> void:
	_banner_show_requested = false
	if _banner_ad != null:
		_banner_ad.hide()


func _create_banner_listener() -> AdListener:
	var listener := AdListener.new()
	listener.on_ad_loaded = func():
		_banner_loading = false
		_banner_retry = -1
		App.log.info("AdMobDriver", "Banner ad loaded")
		if _banner_show_requested and _banner_ad != null:
			_banner_ad.show()

	listener.on_ad_failed_to_load = func(load_ad_error: LoadAdError):
		_banner_loading = false
		App.log.warn("AdMobDriver", "Banner ad failed to load: %s" % load_ad_error.message)
		_retry_load_banner()

	return listener


func _retry_load_banner() -> void:
	_banner_retry = mini(_banner_retry + 1, 3)
	var delays: Array[float] = [2.0, 5.0, 10.0, 20.0]
	var delay: float = delays[_banner_retry]
	App.log.info("AdMobDriver", "Retry loading banner ad in %.1fs" % delay)
	await TimeUtils.wait_safe(App, delay)
	load_banner()
#endregion


#region Platform Unit IDs
func _rewarded_unit_id() -> String:
	return PlatformCatalog.AD_REWARDED_IOS if App.env.is_ios() else PlatformCatalog.AD_REWARDED_ANDROID


func _interstitial_unit_id() -> String:
	return PlatformCatalog.AD_INTERSTITIAL_IOS if App.env.is_ios() else PlatformCatalog.AD_INTERSTITIAL_ANDROID


func _banner_unit_id() -> String:
	return PlatformCatalog.AD_BANNER_IOS if App.env.is_ios() else PlatformCatalog.AD_BANNER_ANDROID
#endregion
