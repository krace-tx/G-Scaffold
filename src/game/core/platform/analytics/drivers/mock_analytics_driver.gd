class_name MockAnalyticsDriver
extends AnalyticsDriver

## Mock 统计打点驱动。
## 在单元测试或开发调试环境下提供安全日志输出，不产生实际网络投递与文件 IO。


func initialize() -> Result:
	App.log.info("MockAnalyticsDriver", "Mock analytics driver initialized")
	return Result.ok()


func log_event(event_name: StringName, params: Dictionary = {}) -> void:
	App.log.debug("MockAnalyticsDriver", "[MockEvent] %s: %s" % [event_name, JSON.stringify(params)])


func set_user_property(prop_name: String, value: Variant) -> void:
	App.log.debug("MockAnalyticsDriver", "[MockUserProperty] %s = %s" % [prop_name, str(value)])
