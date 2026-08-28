class_name AssetService
extends Node

## 按 [code]res://[/code] 路径异步加载资源。已加载过的走缓存。
## 调用方必须 [code]await[/code] [method load]；不要先接到变量上再二次 await。
## [method release] / [method clear] 只放掉本服务的引用；正在 [method load] 的完成后也不再写回。
## TTL 与内存上限只决定是否留在缓存；[method load] 成功时调度方一定能拿到 [Resource]。

#region Constants & Enums
## 未传参时的缓存估算上限。贴图按 RGBA8 上界；默认 32MB，给低端机留余量。
const _DEFAULT_MAX_BYTES: int = 32 * 1024 * 1024
## 未再次 [method load] 命中超过此时长则过期；默认 2 分钟，闲置尽快放槽。
const _DEFAULT_TTL_MSEC: int = 2 * 60 * 1000
## 估算占用达到上限的这个比例就开始挤；默认 80%，避免顶格才动。
const _WATERMARK: float = 0.8
## PackedScene 等估不出体积时计入水位的占位，避免上限被架空。
const _UNKNOWN_BYTES: int = 256 * 1024
## 闲置扫描间隔。内存淘汰走入库时的 [method BudgetCache.flush]，Timer 不必更勤，以免低端机卡顿。
const _FLUSH_INTERVAL_MSEC: int = 30 * 1000
#endregion

#region State
## 已完成的加载。TTL / 水位 / LRU 由 [BudgetCache] 管。
var _cache: BudgetCache

## 尚未结束的加载（同一 path 只打一次 I/O）。
## key: [String] 与 [_cache] 相同的路径
## value: [code]null[/code] = 仍在读盘；[Result] = 已完成，等其它并发 [method load] 取走
var _inflight: Dictionary = {}

## [method release] 发生在 load 完成前：完成后不要写进 [_cache]。
## key: [String] 路径；value: [code]true[/code]
var _released: Dictionary = {}
#endregion

#region Lifecycle
func _init(max_bytes: int = _DEFAULT_MAX_BYTES, ttl_msec: int = _DEFAULT_TTL_MSEC) -> void:
	_cache = BudgetCache.new(max_bytes, ttl_msec, _WATERMARK)
	var timer := Timer.new()
	timer.wait_time = _FLUSH_INTERVAL_MSEC / 1000.0
	timer.autostart = true
	timer.timeout.connect(_cache.flush.bind(0))
	add_child(timer)
#endregion

#region Public API
## 加载 [param path]。必须 [code]await[/code] 才能拿到 [Result]；成功时 [member Result.value] 为 [Resource]。
func load(path: String) -> Result:
	# 1. 空路径直接失败。命中缓存时不要 exists（低端机上反复查 PCK 也贵）。
	if path.is_empty():
		return Result.err("Load failed: path is empty.")

	# 2. 已经在内存里：同步返回，不再 I/O。命中续 TTL；过期则当 miss，下面再读盘。
	var cached: Variant = _cache.read(path)
	if cached != null:
		return Result.ok(cached)

	# 3. 别人正在加载同一份：挂到那次请求上，避免重复读盘。
	if _inflight.has(path):
		return await _join_inflight(path)

	# 4. 自己当发起方：先确认磁盘上有，再占坑读盘。
	if not ResourceLoader.exists(path):
		return Result.err("Asset not found: %s." % path)
	_inflight[path] = null
	var fetched := await _fetch(path)
	_inflight[path] = fetched
	# 完成前已被 release / clear：调用方仍拿到 Result，只是不占槽。失败也要清标记，避免漏到下一次 load。
	if _released.has(path):
		_released.erase(path)
	elif fetched.is_ok():
		# 估算体积并入库；放不下就不占槽，Result 照还。
		var info := MemoryUtils.inspect(fetched.value as Resource)
		var new_bytes: int = int(info.bytes) if info.known else _UNKNOWN_BYTES
		if _cache.put(path, fetched.value, new_bytes, 0):
			# 让出一帧给等待者期间，禁止把刚入库的这条挤掉。
			_cache.pin(path)

	# 5. 再让出一帧，让步骤 3 里的等待者读到 Result，然后再清坑。
	await get_tree().process_frame
	_cache.unpin(path)
	_inflight.erase(path)
	return fetched


## 释放 [param path] 占用的缓存槽。空路径 / 不在缓存里是空操作。
## 不取消进行中的 [method load]；若正在加载，完成后也不再写回。
func release(path: String) -> void:
	if path.is_empty():
		return
	_cache.drop(path)
	if _inflight.has(path):
		_released[path] = true


## 丢掉全部缓存。正在 [method load] 的完成后也不再写回。
func clear() -> void:
	_cache.clear()
	for inflight_path in _inflight:
		_released[inflight_path] = true
#endregion


#region Internal
## 挂到已有的同 path 加载上，避免重复读盘。可 await。
## 发起方写完后优先走 [_cache]；未入树或坑被清掉则失败。
func _join_inflight(path: String) -> Result:
	var tree := get_tree()
	if tree == null:
		return Result.err("Asset load failed: %s." % path)
	# 坑还在且值为 null：发起方还在读盘，继续等。
	while _inflight.has(path) and _inflight[path] == null:
		await tree.process_frame
	# 发起方已写入缓存或 Result；优先走缓存。
	var cached: Variant = _cache.read(path)
	if cached != null:
		return Result.ok(cached)
	var done: Result = _inflight.get(path)
	if done == null:
		return Result.err("Asset load failed: %s." % path)
	return done


## 向引擎登记后台加载并每帧 poll。可 await。未入树不能调用。
## [constant ERR_BUSY] 表示同 path 已在引擎队列里，直接去问进度。
func _fetch(path: String) -> Result:
	# 1. 异步等待依赖 SceneTree；未入树不能 load。
	var tree := get_tree()
	if tree == null:
		return Result.err("Asset load failed: %s." % path)

	# 2. 向引擎登记后台加载。ERR_BUSY = 同 path 已在引擎队列里，直接去 poll。
	var err := ResourceLoader.load_threaded_request(path)
	if err != OK and err != ERR_BUSY:
		return Result.err("Asset load failed: %s." % path)

	# 3. 每帧问一次进度：进行中让出主线程；完成取 Resource；其余当失败。
	while true:
		var status := ResourceLoader.load_threaded_get_status(path)
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				await tree.process_frame
			ResourceLoader.THREAD_LOAD_LOADED:
				var res := ResourceLoader.load_threaded_get(path)
				if res == null:
					return Result.err("Asset load failed: %s." % path)
				return Result.ok(res)
			_:
				return Result.err("Asset load failed: %s." % path)
	return Result.err("Asset load failed: %s." % path)
#endregion
