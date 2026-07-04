class_name NullAnalyticsProvider
extends AnalyticsProvider

## 统计的 Null 实现:打点先落日志。编辑器 / 无 SDK / 降级时使用,让打点调用在
## 任何环境都能安全跑通(只是不真正上报)。

#region Public API
func initialize() -> bool:
	App.log.info("analytics", "null analytics provider initialized")
	return true


func track(event: StringName, params: Dictionary) -> void:
	App.log.info("analytics", "track %s %s" % [event, params])
#endregion
