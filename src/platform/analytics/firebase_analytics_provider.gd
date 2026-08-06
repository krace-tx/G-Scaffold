class_name FirebaseAnalyticsProvider
extends PlatformProvider

## Firebase统计打点契约

#region 变量
var _analytics: Object = null ## Firebase Analytics 单例引用
#endregion

#region 生命周期
func initialize() -> bool:
	if Engine.has_singleton("GodotxFirebaseCore"):
		var firebase_core: Object = Engine.get_singleton("GodotxFirebaseCore")
		firebase_core.core_initialized.connect(_on_core_initialized)
		firebase_core.initialize()
		App.log.info("FirebaseAnalyticsProvider", "Firebase core initialize success")
	else:
		App.log.error("FirebaseAnalyticsProvider", "Firebase core initialize not found")
		return false

	if Engine.has_singleton("GodotxFirebaseAnalytics"):
		_analytics = Engine.get_singleton("GodotxFirebaseAnalytics")
		App.log.info("FirebaseAnalyticsProvider", "Firebase analytics initialize success")
	else:
		App.log.error("FirebaseAnalyticsProvider", "Firebase analytics initialize not found")
		return false
	
	App.log.info("FirebaseAnalyticsProvider", "Firebase analytics provider initialized")
	return true
	
	
## Firebase Core 初始化完成回调
func _on_core_initialized(success: bool) -> void:
	if success and _analytics:
		_analytics.initialize()
		App.log.info("FirebaseAnalyticsProvider", "Firebase core analytics initialize success")
	else:
		App.log.error("FirebaseAnalyticsProvider", "Firebase core analytics initialize failed")
#endregion


func track(event_type: StringName, event_data: Dictionary) -> bool:
	_analytics.log_event(event_type, event_data)
	return true
