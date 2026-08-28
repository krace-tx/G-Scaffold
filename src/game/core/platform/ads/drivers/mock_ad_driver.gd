class_name MockAdDriver
extends AdDriver

## Mock 广告驱动。
## 在 PC / 编辑器或无广告插件环境下提供安全的模拟逻辑，保证业务流程畅通。


func initialize() -> Result:
	App.log.info("MockAdDriver", "Mock ads driver initialized")
	return Result.ok()


func is_rewarded_ready() -> bool:
	return true


func load_rewarded() -> void:
	App.log.debug("MockAdDriver", "Mock rewarded ad preloaded")


func show_rewarded() -> Result:
	await App.get_tree().process_frame
	App.log.info("MockAdDriver", "Mock rewarded ad shown and reward granted")
	return Result.ok()


func is_interstitial_ready() -> bool:
	return true


func load_interstitial() -> void:
	App.log.debug("MockAdDriver", "Mock interstitial ad preloaded")


func show_interstitial() -> Result:
	await App.get_tree().process_frame
	App.log.info("MockAdDriver", "Mock interstitial ad shown and closed")
	return Result.ok()


func load_banner() -> void:
	App.log.debug("MockAdDriver", "Mock banner ad preloaded")


func show_banner() -> void:
	App.log.debug("MockAdDriver", "Mock banner ad shown")


func hide_banner() -> void:
	App.log.debug("MockAdDriver", "Mock banner ad hidden")
