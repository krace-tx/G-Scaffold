class_name NodeUtils
extends RefCounted

## 节点操作工具类。
##
## 封装原生的 add_child 与销毁操作，提供空值防御、去重命名等基建能力。
## 严格遵循项目“可失败操作走 Result，没静默吞错”的规范。

#region Public API
## 安全地实例化并挂载一个场景节点。[br]
## [param scene] 要实例化的预制体；[param parent] 挂载的目标父节点。[br]
## [param custom_name] 可选，指定节点名称以优化场景树渲染性能。[br]
## 返回 [Result]：成功时 [member Result.value] 为挂载后的 [Node] 实例；失败时返回详细错误说明。
static func spawn(scene: PackedScene, parent: Node, custom_name: String = "") -> Result:
	# 1. 卫语句：拦截空指针
	if not is_instance_valid(scene):
		return Result.err("Spawn 失败: 传入的 PackedScene 为空或已失效")
	if not is_instance_valid(parent):
		return Result.err("Spawn 失败: 目标父节点为空或已失效")

	# 2. 实例化
	var instance := scene.instantiate()
	if instance == null:
		return Result.err("Spawn 失败: 场景实例化返回 null")

	# 3. 性能优化的提前命名
	if custom_name != "":
		instance.name = custom_name

	# 4. 卫语句：拦截父节点冲突
	if instance.get_parent() != null:
		return Result.err("Spawn 失败: 实例 [%s] 已经存在父节点" % instance.name)

	# 5. 安全挂载
	parent.add_child(instance)
	return Result.ok(instance)


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
