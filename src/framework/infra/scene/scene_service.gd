class_name SceneService
extends Node

## 顶层场景路由与栈管理服务 (Scene Service Facade)。
## 
## [b]核心职责与设计哲学：[/b]
## 1. [b]极简门面 API[/b]：对外提供一目了然的场景路由接口（[method replace] / [method push] / [method pop] / [method bind]）；
## 2. [b]苹果/字节级流式交互[/b]：摒弃黑屏/遮罩掩耳盗铃，默认智能匹配视差侧滑与景深弹性缩放；
## 3. [b]串行防重入请求队列调度[/b]：防手速连点导致的场景栈错乱与内存撕裂；
## 4. [b]事件解耦广播[/b]：在场景流转完成后广播全局 [signal Bus.scene_changed] 事件。

#region Enums & Constants
## 场景切换过渡动画类型（转接自 SceneTransition）
const TransitionType := SceneTransition.TransitionType
#endregion

#region Private Members
var _stack: SceneStack
var _transition: SceneTransition
var _switching: bool = false
var _pending: Dictionary = {}
#endregion


#region Lifecycle
func _init() -> void:
	_transition = SceneTransition.new(self)
	_stack = SceneStack.new(self, _transition)
#endregion


#region Public API - Status Queries
## 获取当前栈顶场景实例；栈空时为 null
func current() -> BaseScene:
	return _stack.current()


## 获取当前场景栈深度
func depth() -> int:
	return _stack.depth()


## 场景栈是否为空
func is_empty() -> bool:
	return _stack.is_empty()
#endregion


#region Public API - Scene Operations
## 替换栈顶场景 (Replace)
## 默认采用 Apple/字节 景深缩放交融（0.95x 弹性推近 + 旧场景 1.04x 散开淡出）
func replace(
	path: String,
	params: Dictionary = {},
	transition: SceneTransition.TransitionType = SceneTransition.TransitionType.AUTO
) -> void:
	_enqueue("replace", path, params, transition)


## 压栈新场景 (Push)
## 默认采用 iOS 经典 30% 视差微退侧滑推进
func push(
	path: String,
	params: Dictionary = {},
	transition: SceneTransition.TransitionType = SceneTransition.TransitionType.AUTO
) -> void:
	_enqueue("push", path, params, transition)


## 弹出栈顶场景 (Pop)
## 默认采用 iOS 经典侧滑回退与下层视差复位
func pop(
	params: Dictionary = {},
	transition: SceneTransition.TransitionType = SceneTransition.TransitionType.AUTO
) -> void:
	_enqueue("pop", "", params, transition)


## 绑定初始主场景为栈底（仅在栈空时合法，通常用于游戏冷启动首屏）
func bind(path: String, scene: BaseScene, params: Dictionary = {}) -> Result:
	if _switching:
		return Result.err("Scene switch in progress.")
	var res := await _stack.bind(path, scene, params)
	if res.is_ok():
		Bus.scene_changed.emit(_stack.current_path())
	return res
#endregion


#region Internal - Command Queue Engine
## 切换进行中再来命令，只记录最后一次，避免连点把栈打乱
func _enqueue(
	op: String,
	path: String,
	params: Dictionary,
	transition: SceneTransition.TransitionType
) -> void:
	_pending = {
		op = op,
		path = path,
		params = params.duplicate(),
		transition = transition,
	}
	_run()


## 串行消化请求队列：驱动场景栈与并行视效动画
func _run() -> void:
	if _switching:
		return
	_switching = true

	while not _pending.is_empty():
		var req: Dictionary = _pending
		_pending = {}

		var trans_type: SceneTransition.TransitionType = req.get("transition", SceneTransition.TransitionType.AUTO)

		# 调度场景栈执行切场（内部与 SceneTransition 深度联动执行无缝流式运动）
		var result: Result
		match req.op:
			"replace":
				result = await _stack.replace(req.path, req.params, trans_type)
			"push":
				result = await _stack.push(req.path, req.params, trans_type)
			"pop":
				result = await _stack.pop(req.params, trans_type)
			_:
				result = Result.err("Unknown scene op: %s" % req.op)

		# 广播切场结果
		if result.is_err():
			App.log.error("SceneService", "%s" % result.error)
			Bus.scene_change_failed.emit(req.path)
		else:
			var current_path := _stack.current_path()
			App.log.info("SceneService", "Now at '%s'." % current_path)
			Bus.scene_changed.emit(current_path)

	_switching = false
#endregion
