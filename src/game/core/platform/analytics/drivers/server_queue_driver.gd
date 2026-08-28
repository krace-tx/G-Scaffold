class_name ServerQueueDriver
extends AnalyticsDriver

## 自研服务端离线队列缓冲上报驱动。
## 驱动 [EventQueue] 进行本地持久化，并通过 [EventReporter] 定时或按需批量投递自研 API。

var _queue := EventQueue.new()
var _reporter := EventReporter.new()


func initialize() -> Result:
	_queue.initialize()
	_reporter.initialize(_queue)
	App.log.info("ServerQueueDriver", "Server queue driver initialized")
	return Result.ok()


func log_event(event_name: StringName, params: Dictionary = {}) -> void:
	_queue.enqueue(event_name, params)


## 直接实时单条投递（不入本地磁盘离线队列）。
func log_event_direct(event_name: StringName, params: Dictionary = {}) -> void:
	var timestamp: int = App.time.now_msec() if App.time != null else int(Time.get_unix_time_from_system() * 1000)
	var payload := [{
		"event_type": String(event_name),
		"event_data": params,
		"server_timestamp": timestamp,
	}]
	_reporter.report_direct(payload)


## 触发一次批量上报。
func report_now() -> void:
	_reporter.report_now()
