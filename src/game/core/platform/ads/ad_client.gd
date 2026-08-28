class_name AdClient
extends RefCounted

## 广告子系统统一入口门面 (Platform.ad)。
## 采用驱动与流水线架构，统一协调底层 AdMob/Mock 驱动与 iOS ATT 授权，向业务层提供极简的广告调用接口。

var _pipeline := AdPipeline.new()


#region Lifecycle
func initialize() -> Result:
	var res := _pipeline.initialize()
	App.log.info("AdClient", "Ads subsystem ready")
	return res
#endregion


#region Public API - Rewarded Ads
## 激励视频是否已就绪。
func is_rewarded_ready() -> bool:
	return _pipeline.is_rewarded_ready()


## 预加载激励视频。
func load_rewarded() -> void:
	_pipeline.load_rewarded()


## 展示激励视频。
## 用户完整观看发奖返回 [method Result.ok]，失败/未准备好/用户提前关闭返回 [method Result.err]。
func show_rewarded(placement: StringName = &"") -> Result:
	App.log.info("AdClient", "Showing rewarded ad (placement='%s')" % placement)
	return await _pipeline.show_rewarded()
#endregion


#region Public API - Interstitial Ads
## 插屏广告是否已就绪。
func is_interstitial_ready() -> bool:
	return _pipeline.is_interstitial_ready()


## 预加载插屏广告。
func load_interstitial() -> void:
	_pipeline.load_interstitial()


## 展示插屏广告。
## 展示并正常关闭返回 [method Result.ok]，失败/未就绪返回 [method Result.err]。
func show_interstitial(placement: StringName = &"") -> Result:
	App.log.info("AdClient", "Showing interstitial ad (placement='%s')" % placement)
	return await _pipeline.show_interstitial()
#endregion


#region Public API - Banner Ads
## 预加载横幅广告。
func load_banner() -> void:
	_pipeline.load_banner()


## 展示底部横幅广告。
func show_banner() -> void:
	_pipeline.show_banner()


## 隐藏横幅广告。
func hide_banner() -> void:
	_pipeline.hide_banner()
#endregion
