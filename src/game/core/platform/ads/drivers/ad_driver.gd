class_name AdDriver
extends RefCounted

## 广告驱动抽象基类。
## 为各广告平台（AdMob、UnityAds、Mock 等）提供统一标准契约。


func initialize() -> Result:
	return Result.ok()


#region Rewarded Ads
func is_rewarded_ready() -> bool:
	return false


func load_rewarded() -> void:
	pass


func show_rewarded() -> Result:
	await App.get_tree().process_frame
	return Result.ok()
#endregion


#region Interstitial Ads
func is_interstitial_ready() -> bool:
	return false


func load_interstitial() -> void:
	pass


func show_interstitial() -> Result:
	await App.get_tree().process_frame
	return Result.ok()
#endregion


#region Banner Ads
func load_banner() -> void:
	pass


func show_banner() -> void:
	pass


func hide_banner() -> void:
	pass
#endregion
