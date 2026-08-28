class_name AnalyticsClient
extends RefCounted

## 统计埋点子系统统一入口门面 (Platform.analytics)。
## 采用驱动与管道架构（参考 PersistService），支持多平台渠道选择与灵活的分发模式。

var _pipeline := AnalyticsPipeline.new()


#region Lifecycle
func initialize() -> Result:
	var res := _pipeline.initialize()
	App.log.info("AnalyticsClient", "Analytics subsystem ready")
	return res
#endregion


#region Public API
## 上报自定义业务事件。
## [param mode] 上报策略模式，默认 [code]ReportMode.ALL[/code]（Firebase 实时 + 本地队列双通道）。
## 亦可指定 [code]ReportMode.FIREBASE_ONLY[/code]、[code]ReportMode.SERVER_ONLY[/code] 或 [code]ReportMode.DIRECT_SERVER[/code]。
func track(event_name: StringName, params: Dictionary = {}, mode: int = ReportMode.ALL) -> void:
	if event_name.is_empty():
		App.log.error("AnalyticsClient", "track failed: event_name cannot be empty")
		return

	_pipeline.dispatch_event(event_name, params, mode)


## 设置用户画像属性。
## [param channel] 目标渠道掩码，默认 [code]AnalyticsChannel.ALL[/code]。
func set_user_property(prop_name: String, value: Variant, channel: int = AnalyticsChannel.ALL) -> void:
	if prop_name.is_empty():
		return

	_pipeline.dispatch_user_property(prop_name, value, channel)


## 立即触发一次自研服务端的批量事件上报。
func report_now() -> void:
	_pipeline.report_now()
#endregion
