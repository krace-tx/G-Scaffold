class_name EventReporter
extends RefCounted

## 统计事件批量上报器。
## 定时从 [EventQueue] 提取离线事件批次，打包后通过 HTTP 投递至自研服务端 API，并在服务端确认接收后清理本地文件缓冲。
## 内置防重入并发控制与延迟补发机制（Deferred Report），保证弱网环境下的数据投递可靠性。

#region Constants & Config
## 单次批量上报的最大事件条数（避免单次 HTTP 请求体积过大）
const MAX_BATCH_SIZE := 250

## 默认自动轮询上报间隔周期（秒）
const REPORT_INTERVAL_SEC := 60.0
#endregion

#region State
## 绑定的本地持久化缓冲队列实例
var _queue: EventQueue = null

## 驱动定时轮询上报的计时器节点
var _timer: Timer = null

## 并发互斥锁标记：当前是否正在执行网络上报循环
var _is_reporting := false

## 延迟补报标记：在上报过程中若再次被触发，则置为 true，确保循环结束后继续补发剩余数据
var _deferred_report := false
#endregion


#region Lifecycle
## 初始化上报器并绑定本地事件队列。
## 自动将计时器节点挂载到 [Platform] 根节点上并启动周期轮询。
func initialize(queue: EventQueue) -> void:
	_queue = queue
	_timer = Timer.new()
	_timer.wait_time = REPORT_INTERVAL_SEC
	_timer.one_shot = false
	NodeUtils.mount_required(_timer, Platform, "AnalyticsReporterTimer")
	_timer.timeout.connect(_on_timer_timeout)
	_timer.start()
#endregion


#region Public API
## 立即触发一次上报并重置定时器周期（常用于关键流程节点或应用即将切入后台时）。
func report_now() -> void:
	if _timer != null:
		_timer.start(REPORT_INTERVAL_SEC)
	_try_start_report()


## 直接实时投递指定事件载荷（跳过本地磁盘离线缓冲队列）。
## [param events_payload] 符合服务端格式规范的事件数组。
func report_direct(events_payload: Array) -> Result:
	if events_payload.is_empty():
		return Result.ok()

	var body := {
		"events": events_payload,
		"develop_mode": not App.env.is_prod(),
	}

	return await App.net.post_request(ApiCatalog.EVENT_REPORT, body)
#endregion


#region Internal - Scheduling & Concurrency
func _on_timer_timeout() -> void:
	_try_start_report()


## 尝试启动上报循环。若当前已有上报正在进行中，则标记延迟补发并直接返回，避免并发冲突。
func _try_start_report() -> void:
	if _is_reporting:
		_deferred_report = true
		return
	_run_report_cycle()


## 循环执行批量上报，直至所有待上报批次处理完毕且无新的延迟补发请求。
func _run_report_cycle() -> void:
	_is_reporting = true
	while true:
		_deferred_report = false
		await _flush_batch()
		# 若本轮上报期间没有产生新的触发请求，则安全退出循环
		if not _deferred_report:
			break
	_is_reporting = false
#endregion


#region Internal - Network Flush
## 从本地队列提取单批次事件并发送至服务端。
func _flush_batch() -> void:
	if _queue == null or _queue.pending_count() == 0:
		return

	# 1. 从队列中拉取最多 MAX_BATCH_SIZE 条数据
	var raw_events := _queue.fetch_batch(MAX_BATCH_SIZE)
	if raw_events.is_empty():
		return

	var events_payload: Array = []
	var loaded_ids: Array[String] = []
	# 使用权威时间源（已校准的服务器时间，未校准则降级为系统时钟）
	var timestamp: int = App.time.now_msec() if App.time != null else int(Time.get_unix_time_from_system() * 1000)

	# 2. 组装上报 Payload 结构
	for event in raw_events:
		var event_id := str(event.get("event_id", ""))
		var event_type := str(event.get("event_type", ""))
		if event_type.is_empty():
			continue

		events_payload.append({
			"event_type": event_type,
			"event_data": event.get("event_data", {}),
			"server_timestamp": timestamp,
		})
		loaded_ids.append(event_id)

	if events_payload.is_empty():
		return

	var body := {
		"events": events_payload,
		"develop_mode": not App.env.is_prod(),
	}

	# 3. 发起网络请求
	var result: Result = await App.net.post_request(ApiCatalog.EVENT_REPORT, body)
	var success := result.is_ok() and bool((result.value as Dictionary).get("success", false))

	# 4. 成功后批量清理已确认的本地事件文件；失败则保留在队列中等待下一轮重试
	if success:
		_queue.remove_batch(loaded_ids)
		App.log.info("EventReporter", "Reported %d events to server" % loaded_ids.size())
	else:
		App.log.warn("EventReporter", "Batch report failed, keep events in queue")
#endregion
