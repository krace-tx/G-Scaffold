class_name SceneService
extends Node

## 顶层场景切换服务:异步加载 + 转场遮罩 + enter/exit 生命周期调度。
##
## 全项目唯一允许调用 change_scene 系 API 的地方,业务一律走 [method replace]。
## 不维护场景栈,不管理关卡内子场景加载,不管理 UI——那些分别是业务代码、
## 关卡系统、UIService 的职责。完整规格见 docs/modules/scene-service.md。
##
## 由 Bootstrap 创建后挂在 [App] 下(而不是当时的 Boot 场景下),这样才能在
## change_scene 把 Boot 场景整个替换掉之后继续存活。

#region Constants & Enums
const _FADE_DURATION: float = 0.2
const _ENTER_TIMEOUT: float = 10.0
const _REGISTRY_PATH: String = "res://src/resource/data/scene_registry.tres"
#endregion

#region Exports & State
var _registry: SceneRegistry
var _current_id: StringName = &""
var _overlay: ColorRect
var _queue: Array[Dictionary] = []
var _is_switching: bool = false
#endregion

#region Lifecycle
func _ready() -> void:
	_registry = load(_REGISTRY_PATH) as SceneRegistry
	_build_overlay()
#endregion

#region Public API
## 切换到 [param scene_id] 对应的顶层场景,经过转场遮罩。多次调用会排队顺序
## 执行,不会并发切换。[param transition] 目前只实现 fade,预留供未来扩展。
func replace(scene_id: StringName, transition: StringName = &"fade") -> void:
	_queue.append({"id": scene_id, "transition": transition})
	_drain_queue()


## 重载当前场景(如"重开本关")。
func reload_current() -> void:
	if _current_id == &"":
		App.log.warn("scene", "reload_current called with no current scene")
		return
	replace(_current_id)


## 当前顶层场景 id,尚未切换过任何场景时为空字符串。
func get_current_id() -> StringName:
	return _current_id
#endregion

#region Internal
func _drain_queue() -> void:
	if _is_switching or _queue.is_empty():
		return
	_is_switching = true
	var request: Dictionary = _queue.pop_front()
	await _switch_to(request.id, request.transition)
	_is_switching = false
	_drain_queue()


func _switch_to(scene_id: StringName, _transition: StringName) -> void:
	var scene_path := _registry.resolve_path(scene_id) if _registry else ""
	if scene_path.is_empty():
		_fail(scene_id, "unknown scene id")
		return

	await _fade_out()

	var packed := await _load_threaded(scene_path)
	if packed == null:
		_fail(scene_id, "failed to load: %s" % scene_path)
		await _fade_in()
		return

	get_tree().change_scene_to_packed(packed)
	_current_id = scene_id
	await get_tree().process_frame   # 等新场景根节点真正入树

	await _run_on_enter(scene_id)
	await _fade_in()
	Bus.scene_changed.emit(scene_id)


func _fail(scene_id: StringName, reason: String) -> void:
	App.log.error("scene", "%s (id=%s)" % [reason, scene_id])
	Bus.scene_change_failed.emit(scene_id)


## 调用新场景的 _on_enter,超过 _ENTER_TIMEOUT 秒仍未完成则记录错误并继续
## (揭开遮罩),避免场景自身的 bug 把玩家永远卡在黑屏。
func _run_on_enter(scene_id: StringName) -> void:
	var base_scene := get_tree().current_scene as BaseScene
	if base_scene == null:
		return

	# 单元素数组做可变完成标记:GDScript lambda 捕获局部变量是按值快照,
	# 若用 bool,lambda 内部的赋值不会反映到这里的循环条件,会一直空转到
	# 超时。Array 是引用类型,捕获的是同一份底层数据,可以跨闭包共享状态。
	var finished := [false]
	(func() -> void:
		await base_scene._on_enter({})
		finished[0] = true
	).call()

	var elapsed := 0.0
	while not finished[0] and elapsed < _ENTER_TIMEOUT:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if not finished[0]:
		_fail(scene_id, "_on_enter exceeded %.0fs timeout" % _ENTER_TIMEOUT)


## 异步请求加载,轮询到完成或失败为止,不阻塞主线程。
func _load_threaded(path: String) -> PackedScene:
	if ResourceLoader.load_threaded_request(path) != OK:
		return null
	while true:
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			return ResourceLoader.load_threaded_get(path) as PackedScene
		if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			return null
		await get_tree().process_frame
	return null   # 不可达:静态分析无法证明 while true 必经某个 return,补一行满足检查


func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	_overlay = ColorRect.new()
	_overlay.color = Color.BLACK
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.modulate.a = 0.0
	layer.add_child(_overlay)
	add_child(layer)


func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(_overlay, "modulate:a", 1.0, _FADE_DURATION)
	await tween.finished


func _fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(_overlay, "modulate:a", 0.0, _FADE_DURATION)
	await tween.finished
#endregion
