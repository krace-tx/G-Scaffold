class_name NodeUtils
extends RefCounted

## 节点操作工具类。
##
## 封装原生的 add_child、销毁、批量清理、ready 等待与 duplicate 操作,
## 提供空值防御、去重命名等基建能力。
## 严格遵循项目“可失败操作走 Result，没静默吞错”的规范。

#region Public API
## 安全地把一个**已实例化**的节点挂载到父节点下。[br]
## 与 [method spawn] 的分工:spawn 从 [PackedScene] 实例化预制体;mount 接管一个已经
## [code]new()[/code] 出来的节点(如各框架服务 [code]SceneService.new()[/code])。[br]
## [param node] 要挂载的节点(调用方持有,失败时不代为释放);[param parent] 目标父节点;[br]
## [param custom_name] 可选,提前命名(在入树前设,避免重命名 + 让调试场景树可读)。[br]
## 返回 [Result]:成功时 [member Result.value] 为该节点;失败返回详细错误。
static func mount(node: Node, parent: Node, custom_name: String = "") -> Result:
	if not is_instance_valid(node):
		return Result.err("Mount 失败: 传入的节点为空或已失效")
	if not is_instance_valid(parent):
		return Result.err("Mount 失败: 目标父节点为空或已失效")

	# 提前命名:入树前设,避免入树后重命名的信号开销,也让调试场景树可读。
	if custom_name != "":
		node.name = custom_name

	# 卫语句:拦截已销毁排队或父节点冲突(不能直接 add_child,会报错或行为未定义)。
	if node.is_queued_for_deletion() or node.get_parent() != null:
		return Result.err("Mount 失败: 节点 [%s] 已被标记销毁或已有父节点" % node.name)

	parent.add_child(node)
	return Result.ok(node)


## 挂载一个**结构上必然成功**的节点(如服务给自己建的子节点),失败即编程 bug。[br]
## 与 [method mount] 的分工:mount 返回 [Result] 给"可能失败、需分支处理"的调用方
## (如游戏代码 spawn 后挂载);mount_required 给"不该失败"的内部基建——失败时
## [code]push_error[/code] 大声报出(绝不静默吞),Debug 下 [code]assert[/code] 中断,
## 并**直接返回该节点**方便链式书写。[br]
## 用 push_error 而非 App.log 是刻意的:NodeUtils 是 core 纯工具,不依赖任何服务/autoload。
static func mount_required(node: Node, parent: Node, custom_name: String = "") -> Node:
	var res := mount(node, parent, custom_name)
	if res.is_err():
		push_error("mount_required 失败: %s" % res.error)
		assert(false, "mount_required 失败: %s" % res.error)
	return node


## 安全地实例化并挂载一个场景节点。[br]
## [param scene] 要实例化的预制体；[param parent] 挂载的目标父节点。[br]
## [param custom_name] 可选，指定节点名称以优化场景树渲染性能。[br]
## 返回 [Result]：成功时 [member Result.value] 为挂载后的 [Node] 实例；失败时返回详细错误说明。
static func spawn(scene: PackedScene, parent: Node, custom_name: String = "") -> Result:
	# 1. 卫语句：拦截空指针
	if not is_instance_valid(scene):
		return Result.err("Spawn 失败: 传入的 PackedScene 为空或已失效")

	# 2. 实例化
	var instance := scene.instantiate()
	if instance == null:
		return Result.err("Spawn 失败: 场景实例化返回 null")

	# 3. 复用 mount 做挂载(命名 + 守卫)。挂载失败要释放刚实例化的孤儿节点,否则泄漏
	#    ——这是 spawn 与 mount 的关键区别:instance 是 spawn 内部造的,由 spawn 负责善后。
	var res := mount(instance, parent, custom_name)
	if res.is_err():
		instance.queue_free()
	return res


## 深/浅拷贝节点并挂载到父节点下。[br]
## [param node] 源节点(仍在树中也可拷贝,副本无父节点);[param parent] 目标父节点;[br]
## [param custom_name] 可选,挂载前命名;[param deep] 为 [code]true[/code] 时递归复制子节点。[br]
## 返回 [Result]:成功时 [member Result.value] 为副本;挂载失败时自动释放副本(同 [method spawn])。
static func clone(node: Node, parent: Node, custom_name: String = "", deep: bool = true) -> Result:
	if not is_instance_valid(node):
		return Result.err("Clone 失败: 源节点为空或已失效")
	if not is_instance_valid(parent):
		return Result.err("Clone 失败: 目标父节点为空或已失效")
	if node.is_queued_for_deletion():
		return Result.err("Clone 失败: 源节点 [%s] 已被标记销毁" % node.name)

	var copy := node.duplicate(deep)
	if copy == null:
		return Result.err("Clone 失败: duplicate() 返回 null")
	if not copy is Node:
		copy.free()
		return Result.err("Clone 失败: duplicate() 结果不是 Node")

	var res := mount(copy as Node, parent, custom_name)
	if res.is_err():
		(copy as Node).queue_free()
	return res


## 安全延迟销毁节点。[br]
## 空值或已排队删除时忽略,避免重复 [code]queue_free()[/code]。
## 交给引擎在本帧末解绑父子并释放,不提前 [code]remove_child[/code](避免多余出树信号)。
static func safe_free(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node.is_queued_for_deletion():
		return
	node.queue_free()


## 批量销毁父节点的全部直接子节点。[br]
## 倒序遍历,避免动态数组偏移;已排队删除的子节点跳过。[br]
## [param immediate] 为 [code]true[/code] 时同步 [code]free()[/code],否则走 [method safe_free]。
static func clear_children(parent: Node, immediate: bool = false) -> void:
	if not is_instance_valid(parent):
		return
	var children := parent.get_children()
	for i in range(children.size() - 1, -1, -1):
		var child: Node = children[i]
		if not is_instance_valid(child) or child.is_queued_for_deletion():
			continue
		if immediate:
			child.free()
		else:
			safe_free(child)


## 安全等待节点 [code]ready[/code](防 Use-After-Free + 超时)。[br]
## 节点须已入树且尚未 ready;已 ready 则立即返回成功。[br]
## 该方法为异步。返回 [Result]:成功表示 ready 已触发且节点仍存活;失败携带原因。
##
## [codeblock]
## var mount_res := NodeUtils.mount(widget, self)
## if mount_res.is_err(): return
## var ready_res := await NodeUtils.wait_for_ready_safe(mount_res.value)
## if ready_res.is_err(): return
## widget.refresh()
## [/codeblock]
static func wait_for_ready_safe(node: Node, timeout_sec: float = 5.0) -> Result:
	if not is_instance_valid(node):
		return Result.err("Wait ready 失败: 节点为空或已失效")
	if node.is_node_ready():
		return Result.ok()
	if not node.is_inside_tree():
		return Result.err("Wait ready 失败: 节点未入树, ready 不会触发")

	var tree := node.get_tree()
	if tree == null:
		return Result.err("Wait ready 失败: 无法获取 SceneTree")

	var elapsed := 0.0
	while elapsed < timeout_sec:
		if not is_instance_valid(node):
			return Result.err("Wait ready 中断: 节点在等待期间已被销毁")
		if node.is_node_ready():
			return Result.ok()
		await tree.process_frame
		elapsed += tree.get_process_delta_time()

	if not is_instance_valid(node):
		return Result.err("Wait ready 中断: 节点在等待期间已被销毁")
	if node.is_node_ready():
		return Result.ok()
	return Result.err("Wait ready 超时 (%.1f 秒)" % timeout_sec)
#endregion
