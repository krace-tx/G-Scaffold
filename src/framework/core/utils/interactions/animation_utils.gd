class_name AnimationUtils
extends RefCounted

## 动画特效工具类。
##
## 提供帧动画（[AnimatedSprite2D]）与 Spine 骨骼动画（[SpineSprite]）的一次性播放、
## 循环播放以及对象池复用能力，用于关卡内高频/临时特效（通关星光、金币光效等）。
## 纯静态工具，播放的节点挂载在调用方传入的 [param node] 之下，播放完成后自动回收，
## 调用方无需手动管理生命周期。

#region Constants
## 特效节点统一置于较高层级，确保盖在常规 UI/游戏元素之上。
const _EFFECT_Z_INDEX: int = 4000

## Spine 对象池自动轮换的最大轨道数（避免瞬时高频触发时相互覆盖）。
const _TRACK_ROTATION: int = 16
#endregion

#region Internal State
static var _spine_pool: Dictionary = {} ## Spine 对象池：{ SpineSkeletonDataResource: Array[SpineSprite] }
static var _track_counter: int = 0 ## 对象池播放时的轨道轮换计数器
#endregion

#region Public API - 帧动画
## 在指定位置播放 [AnimatedSprite2D] 帧动画，播放结束后自动释放。
static func play_anim_at(node: Node, frames: SpriteFrames, animation_name: String, pos: Vector2) -> AnimatedSprite2D:
	var anim_sprite := AnimatedSprite2D.new()
	anim_sprite.sprite_frames = frames
	anim_sprite.z_index = _EFFECT_Z_INDEX

	node.add_child.call_deferred(anim_sprite)
	await anim_sprite.tree_entered

	anim_sprite.global_position = pos
	anim_sprite.play(animation_name)
	anim_sprite.animation_finished.connect(func() -> void:
		anim_sprite.queue_free()
	)
	return anim_sprite
#endregion

#region Public API - Spine 单次
## 在指定位置播放单次 Spine 动画（非对象池）。[param auto_free] 为 true 时播放完成后自动释放。
static func play_spine_at(node: Node, skeleton_data_res: SpineSkeletonDataResource, animation_name: String, pos: Vector2, scale: Vector2 = Vector2.ONE, track_index: int = 0, auto_free: bool = true) -> SpineSprite:
	var spine_sprite := SpineSprite.new()
	spine_sprite.skeleton_data_res = skeleton_data_res
	spine_sprite.z_index = _EFFECT_Z_INDEX
	spine_sprite.scale = scale

	node.add_child(spine_sprite)
	spine_sprite.global_position = pos

	var state := spine_sprite.get_animation_state()
	# Spine 参数顺序：(animation_name, loop, track_index)
	state.set_animation(animation_name, false, track_index)

	if auto_free:
		spine_sprite.animation_completed.connect(func(_sprite: Variant, _state: Variant, _track_entry: Variant) -> void:
			if is_instance_valid(spine_sprite):
				spine_sprite.queue_free()
		)
	return spine_sprite
#endregion

#region Public API - Spine 循环
## 在指定位置循环播放 Spine 动画。[param duration] >= 0 时到期自动销毁，否则常驻直到手动释放。
static func play_spine_loop_at(node: Node, skeleton_data_res: SpineSkeletonDataResource, animation_name: String, pos: Vector2, scale: Vector2 = Vector2.ONE, track_index: int = 0, duration: float = -1.0) -> SpineSprite:
	var spine_sprite := SpineSprite.new()
	spine_sprite.skeleton_data_res = skeleton_data_res
	spine_sprite.z_index = _EFFECT_Z_INDEX
	spine_sprite.scale = scale

	node.add_child(spine_sprite)

	# 异步安全检查：节点可能在入树过程中被外部释放
	if not is_instance_valid(spine_sprite) or not spine_sprite.is_inside_tree():
		return spine_sprite

	spine_sprite.global_position = pos

	var state := spine_sprite.get_animation_state()
	if state:
		state.set_animation(animation_name, true, track_index)

	if duration >= 0.0:
		var timer: SceneTreeTimer = node.get_tree().create_timer(duration)
		timer.timeout.connect(func() -> void:
			if is_instance_valid(spine_sprite):
				spine_sprite.queue_free()
		)
	return spine_sprite
#endregion

#region Public API - Spine 对象池
## 从对象池获取或创建 Spine 节点并播放单次动画，适用于高频特效以减少频繁创建/销毁开销。
static func play_spine_from_pool(
	node: Node,
	skeleton_data_res: SpineSkeletonDataResource,
	animation_name: String,
	pos: Vector2,
	pool_limit: int = 10,
	scale: Vector2 = Vector2.ONE
) -> SpineSprite:
	var spine_sprite: SpineSprite

	if not _spine_pool.has(skeleton_data_res):
		_spine_pool[skeleton_data_res] = []
	var pool: Array = _spine_pool[skeleton_data_res]

	# 优先复用池中已闲置（不在场景树内）的节点
	for s: SpineSprite in pool:
		if is_instance_valid(s) and not s.is_inside_tree():
			spine_sprite = s
			break

	if not spine_sprite:
		if pool.size() < pool_limit:
			spine_sprite = SpineSprite.new()
			spine_sprite.skeleton_data_res = skeleton_data_res
			pool.append(spine_sprite)
		else:
			# 池已满：强制回收最早的节点循环使用
			spine_sprite = pool[0]
			if spine_sprite.is_inside_tree():
				spine_sprite.get_parent().remove_child(spine_sprite)

	spine_sprite.z_index = _EFFECT_Z_INDEX
	spine_sprite.scale = scale
	node.add_child(spine_sprite)
	spine_sprite.global_position = pos

	var state := spine_sprite.get_animation_state()
	var skeleton := spine_sprite.get_skeleton()

	# 重置并清理旧轨道数据
	skeleton.set_to_setup_pose()
	state.clear_tracks()

	# 自动轮换轨道：解决瞬时高频触发时的覆盖问题
	var current_track: int = _track_counter % _TRACK_ROTATION
	_track_counter += 1
	state.set_animation(animation_name, false, current_track)

	# 确保信号连接（新节点仅连接一次）
	if not spine_sprite.animation_completed.is_connected(_on_animation_completed):
		spine_sprite.animation_completed.connect(_on_animation_completed.bind(spine_sprite))
	return spine_sprite


## 清理指定资源的对象池；[param skeleton_data_res] 为空时清理全部池子（通常在切换大关卡时调用）。
static func clear_spine_pool(skeleton_data_res: SpineSkeletonDataResource = null) -> void:
	if skeleton_data_res:
		if _spine_pool.has(skeleton_data_res):
			var pool: Array = _spine_pool[skeleton_data_res]
			for spine_sprite: SpineSprite in pool:
				if is_instance_valid(spine_sprite):
					# 仍在场景树中的节点需先移除再释放
					if spine_sprite.is_inside_tree():
						spine_sprite.get_parent().remove_child(spine_sprite)
					spine_sprite.queue_free()
			_spine_pool.erase(skeleton_data_res)
	else:
		for res: Variant in _spine_pool.keys():
			clear_spine_pool(res as SpineSkeletonDataResource)
		_spine_pool.clear()

	# 重置轨道计数器，防止数值无限增长
	_track_counter = 0
	App.log.debug("AnimationUtils", "Spine object pool cleared")


## 清理池内所有闲置节点，保留池结构（内存回收但不影响后续复用）。
static func flush_idle_nodes() -> void:
	for res: Variant in _spine_pool.keys():
		var pool: Array = _spine_pool[res]
		var i := pool.size() - 1
		while i >= 0:
			var s: SpineSprite = pool[i]
			if is_instance_valid(s) and not s.is_inside_tree():
				s.queue_free()
				pool.remove_at(i)
			i -= 1
#endregion

#region Internal
## Spine 动画播放完成回调：将节点从场景树移回池中待复用。
static func _on_animation_completed(_sprite: SpineSprite, _state: SpineAnimationState, _track: SpineTrackEntry, caller_sprite: SpineSprite) -> void:
	if is_instance_valid(caller_sprite) and caller_sprite.get_parent():
		caller_sprite.get_parent().remove_child(caller_sprite)
#endregion
