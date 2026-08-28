class_name FirebaseDriver
extends AnalyticsDriver

## Firebase Analytics 实时打点驱动。
## 封装与 GodotxFirebaseCore 及 GodotxFirebaseAnalytics 原生单例的生命周期绑定与事件上报。
## 在真机环境下直接向 Google Firebase 发送实时统计数据；在编辑器或插件缺失环境下自动打印调试日志兜底。

#region State
## GodotxFirebaseAnalytics 原生单例对象引用（未初始化或不支持平台为 null）
var _analytics: Object = null
#endregion


#region Lifecycle
## 初始化 Firebase 核心与统计模块。
## 优先拉起 Firebase Core，并在其就绪回调后初始化 Analytics 模块；单例不存在时平滑返回 [method Result.ok]。
func initialize() -> Result:
	# 1. 检查 Firebase 核心单例（由 Godot 原生插件导出提供）
	if not Engine.has_singleton("GodotxFirebaseCore"):
		App.log.warn("FirebaseDriver", "Firebase core singleton not found, fallback to mock")
		return Result.ok()

	# 2. 绑定 Core 初始化完成回调并触发初始化
	var core = Engine.get_singleton("GodotxFirebaseCore")
	core.core_initialized.connect(_on_core_initialized)
	core.initialize()

	# 3. 预先获取 Analytics 单例引用
	if Engine.has_singleton("GodotxFirebaseAnalytics"):
		_analytics = Engine.get_singleton("GodotxFirebaseAnalytics")
	else:
		App.log.warn("FirebaseDriver", "Firebase analytics singleton not found")

	return Result.ok()


## Firebase Core 初始化完成的回调处理。
## 当且仅当 Core 初始化成功后，方可对 Analytics 统计模块执行 initialize()。
func _on_core_initialized(success: bool) -> void:
	if success and _analytics != null:
		_analytics.initialize()
		App.log.info("FirebaseDriver", "Firebase analytics initialized successfully")
	else:
		App.log.warn("FirebaseDriver", "Firebase core init failed or analytics unavailable")
#endregion


#region Public API
## 实时上报业务打点事件。
## [param event_name] 事件名称；[param params] 携带的字典参数。
## 若原生单例就绪则调用其 log_event，否则打印 Debug 日志。
func log_event(event_name: StringName, params: Dictionary = {}) -> void:
	if _analytics == null:
		App.log.debug("FirebaseDriver", "[Mock] log_event: %s | %s" % [event_name, JSON.stringify(params)])
		return
	_analytics.log_event(event_name, params)


## 设置用户画像/分群属性（如渠道来源、玩家等级等）。
## [param prop_name] 属性名；[param value] 属性值。
func set_user_property(prop_name: String, value: Variant) -> void:
	if _analytics != null and _analytics.has_method("set_user_property"):
		_analytics.set_user_property(prop_name, str(value))
		return
	App.log.debug("FirebaseDriver", "[Mock] set_user_property: %s = %s" % [prop_name, str(value)])
#endregion
