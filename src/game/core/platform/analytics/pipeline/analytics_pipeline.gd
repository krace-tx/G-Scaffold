class_name AnalyticsPipeline
extends RefCounted

## 统计打点调度管道。
## 借鉴 PersistService 调度架构，持有各驱动实例，按 [ReportMode] 和 [AnalyticsChannel] 将事件分发至目标通道。

var _firebase_driver := FirebaseDriver.new()
var _server_driver := ServerQueueDriver.new()


func initialize() -> Result:
	_firebase_driver.initialize()
	_server_driver.initialize()
	App.log.info("AnalyticsPipeline", "Analytics pipeline initialized")
	return Result.ok()


## 按策略分发自定义业务事件。
func dispatch_event(event_name: StringName, params: Dictionary, mode: int = ReportMode.ALL) -> void:
	match mode:
		ReportMode.ALL:
			_firebase_driver.log_event(event_name, params)
			_server_driver.log_event(event_name, params)
		ReportMode.FIREBASE_ONLY:
			_firebase_driver.log_event(event_name, params)
		ReportMode.SERVER_ONLY:
			_server_driver.log_event(event_name, params)
		ReportMode.DIRECT_SERVER:
			_server_driver.log_event_direct(event_name, params)
		_:
			App.log.warn("AnalyticsPipeline", "Unknown ReportMode: %d, fallback to ALL" % mode)
			_firebase_driver.log_event(event_name, params)
			_server_driver.log_event(event_name, params)


## 按渠道掩码分发用户属性设置。
func dispatch_user_property(prop_name: String, value: Variant, channel: int = AnalyticsChannel.ALL) -> void:
	if channel & AnalyticsChannel.FIREBASE:
		_firebase_driver.set_user_property(prop_name, value)
	if channel & AnalyticsChannel.SERVER:
		# 若未来自研服务端支持用户属性，可在此处扩展接入
		pass


## 立即触发服务端批量投递。
func report_now() -> void:
	_server_driver.report_now()
