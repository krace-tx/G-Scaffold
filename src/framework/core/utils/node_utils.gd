class_name NodeUtils
extends RefCounted

## 节点操作工具类。
##
## 封装原生的 add_child 与销毁操作，提供空值防御、去重命名等基建能力。
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

	# 卫语句:拦截父节点冲突(已挂在别处的节点不能直接 add_child,会报错)。
	if node.get_parent() != null:
		return Result.err("Mount 失败: 节点 [%s] 已经存在父节点" % node.name)

	parent.add_child(node)
	return Result.ok(node)


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


## 安全移除并清理节点。[br]
## 避免直接调用 queue_free() 导致的野指针崩溃。如果节点为空或已在排队删除，则安全忽略。
static func safe_free(node: Node) -> void:
	# 检查节点实例是否仍然有效（未被销毁且非空）
	if not is_instance_valid(node):
		return
		
	# 检查节点是否已经被标记为待释放
	# 避免重复调用 queue_free() 导致的错误
	if node.is_queued_for_deletion():
		return

	# 从场景树中剥离，防止当前帧逻辑继续触发
	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
		
	node.queue_free()
#endregion
