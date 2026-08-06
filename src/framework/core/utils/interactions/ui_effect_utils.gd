class_name UiEffectUtils
extends RefCounted

## UI 交互特效工具类。
##
## 为 [Control] 节点提供常用的缩放、弹出、卡牌翻转与按压反馈等补间动画。
## 纯静态工具，动画由传入节点自身的 [method Node.create_tween] 驱动，
## 调用方无需手动管理 [Tween] 生命周期（随节点释放而自动结束）。

#region Public API - 缩放动画
## 将 [Control] 节点缩放到目标比例（轴心自动居中）。
static func animate_scale(node: Control, scale: float = 1.0, duration: float = 0.1) -> Tween:
	node.pivot_offset = node.size / 2
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector2(scale, scale), duration)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	return tween


## 通用「弹出」缩放动画：从 [param start] 放大到 [param peak] 再回落到 [param end]。
static func pop_scale(node: Control, start: float = 1.0, peak: float = 1.1, end: float = 1.0, duration: float = 0.25) -> Tween:
	if not node:
		return null

	# 确保轴心点在中心，否则会从左上角缩放
	node.pivot_offset = node.size / 2
	node.scale = Vector2(start, start)

	var tween := node.create_tween()
	# 时间分配：第一阶段快速放大，第二阶段带缓冲回落
	var t1 := duration * 0.6
	var t2 := duration * 0.4

	tween.tween_property(node, "scale", Vector2(peak, peak), t1)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2(end, end), t2)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN_OUT)
	return tween
#endregion

#region Public API - 翻转动画
## 卡牌翻转动画：在动画中点切换正反面（[param front]/[param back]）的可见性。
static func flip_card(card: Control, front: CanvasItem, back: CanvasItem, duration: float = 0.4) -> Tween:
	var tween := card.create_tween()

	# 确保轴心点在中心，否则翻转会从左边开始
	card.pivot_offset = card.size / 2

	# 第一阶段：横向收缩到侧面（宽度变为 0）
	tween.tween_property(card, "scale:x", 0.0, duration / 2)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)

	# 中间点回调：切换正反面显示（仅在第一段动画结束时触发）
	tween.step_finished.connect(func(idx: int) -> void:
		if idx == 0:
			front.visible = not front.visible
			back.visible = not back.visible
	)

	# 第二阶段：从 0 恢复到 1.0
	tween.tween_property(card, "scale:x", 1.0, duration / 2)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	return tween
#endregion

#region Public API - 交互反馈
## 为节点应用「按住放大、松开缩小」的通用按压反馈效果。
static func apply_press_select_effect(node: Control, trigger_button: BaseButton) -> void:
	if not node or not trigger_button:
		return

	node.pivot_offset = node.size / 2

	trigger_button.button_down.connect(func() -> void:
		_create_simple_scale(node, Vector2(1.05, 1.05))
	)

	var reset_scale := func() -> void:
		_create_simple_scale(node, Vector2.ONE)
	trigger_button.button_up.connect(reset_scale)
	trigger_button.mouse_exited.connect(reset_scale)
#endregion

#region Internal
## 执行一段简单的缩放补间。
static func _create_simple_scale(node: Control, target_scale: Vector2) -> void:
	var tween := node.create_tween()
	tween.tween_property(node, "scale", target_scale, 0.1)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
#endregion
