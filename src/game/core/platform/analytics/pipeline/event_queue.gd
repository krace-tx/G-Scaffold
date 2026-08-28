class_name EventQueue
extends RefCounted

## 本地离线事件持久化缓冲队列。
## 负责事件落盘、索引文件维护与批量提取/移除，实现弱网环境下的数据兜底与可靠投递。

var _pending_event_ids: Array[String] = []


func initialize() -> void:
	_load_index()


## 将自定义事件入队并持久化落盘。
func enqueue(event_name: StringName, params: Dictionary) -> void:
	var event_id := UuidUtils.v4()
	var payload := {
		"event_id": event_id,
		"event_type": String(event_name),
		"event_data": params,
	}

	var file_path := _event_file_path(event_id)
	var res := FileUtils.write_json(file_path, payload)
	if res.is_err():
		App.log.error("EventQueue", "Failed to enqueue event %s: %s" % [event_id, res.error])
		return

	if event_id not in _pending_event_ids:
		_pending_event_ids.append(event_id)
		_save_index()


## 提取待上报的事件列表（限制最大批次数量）。
func fetch_batch(max_batch_size: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event_id in _pending_event_ids:
		if result.size() >= max_batch_size:
			break
		var res := FileUtils.read_json(_event_file_path(event_id))
		if res.is_err() or not res.value is Dictionary:
			continue
		result.append(res.value as Dictionary)
	return result


## 批量移除已确认成功上报的事件。
func remove_batch(event_ids: Array[String]) -> void:
	for event_id in event_ids:
		if event_id.is_empty():
			continue
		FileUtils.remove_file(_event_file_path(event_id))
		_pending_event_ids.erase(event_id)
	_save_index()


func pending_count() -> int:
	return _pending_event_ids.size()


#region Internal
func _event_file_path(event_id: String) -> String:
	return StorageCatalog.DIR_ANALYTICS_EVENTS + event_id + ".json"


func _load_index() -> void:
	_pending_event_ids.clear()
	if not FileUtils.file_exists(StorageCatalog.ANALYTICS_EVENT_INDEX):
		return

	var file := FileAccess.open(StorageCatalog.ANALYTICS_EVENT_INDEX, FileAccess.READ)
	if file == null:
		return

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if not line.is_empty() and FileUtils.file_exists(_event_file_path(line)):
			_pending_event_ids.append(line)
	file.close()


func _save_index() -> void:
	DirAccess.make_dir_recursive_absolute(StorageCatalog.DIR_ANALYTICS_EVENTS)
	var file := FileAccess.open(StorageCatalog.ANALYTICS_EVENT_INDEX, FileAccess.WRITE)
	if file == null:
		App.log.error("EventQueue", "Failed to save event index")
		return

	for event_id in _pending_event_ids:
		file.store_line(event_id)
	file.close()
#endregion
