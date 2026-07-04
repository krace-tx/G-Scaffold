class_name TimeUtils
extends RefCounted

## 时间处理与安全挂起工具类。
##
## 提供毫秒/秒的格式化显示，以及与节点生命周期强绑定的安全异步等待（Wait）功能。
## 详见 docs/conventions/coding-style.md 中关于 await 纪律的说明。

#region Constants & Enums
const SECONDS_PER_MINUTE: int = 60
const SECONDS_PER_HOUR: int = 3600
const MS_PER_SECOND: int = 1000
#endregion

#region Public API
## 将秒数格式化为 MM:SS 字符串（例如 03:05）。[br]
## 常用于倒计时或局内游戏时间显示。
static func format_mm_ss(total_seconds: int) -> String:
	var m := total_seconds / SECONDS_PER_MINUTE
	var s := total_seconds % SECONDS_PER_MINUTE
	return "%02d:%02d" % [m, s]


## 将秒数格式化为 HH:MM:SS 字符串（例如 01:25:09）。[br]
## 常用于长线挂机奖励倒计时。
static func format_hh_mm_ss(total_seconds: int) -> String:
	var h := total_seconds / SECONDS_PER_HOUR
	var rem := total_seconds % SECONDS_PER_HOUR
	var m := rem / SECONDS_PER_MINUTE
	var s := rem % SECONDS_PER_MINUTE
	return "%02d:%02d:%02d" % [h, m, s]


## 安全的异步等待（防 Use-After-Free）。[br]
## 挂起当前协程 [param seconds] 秒。在恢复执行时，会自动校验传入的 [param node] 是否依然存活。[br]
## 该方法为异步。返回 [Result]：成功表示等待结束且节点存活；失败表示节点在等待期间已被销毁。
##
## [codeblock]
## var wait_res := await TimeUtils.wait_safe(self, 2.0)
## if wait_res.is_err(): return # 节点已死，直接退出，绝不继续执行后续逻辑
## 
## _fire_projectile()
## [/codeblock]
static func wait_safe(node: Node, seconds: float) -> Result:
	# 1. 卫语句：初始状态校验
	if not is_instance_valid(node):
		return Result.err("Wait 失败: 传入的节点为空或已失效")
		
	var tree := node.get_tree()
	if tree == null:
		return Result.err("Wait 失败: 节点当前不在场景树中")
		
	# 2. 执行真正的挂起等待 ( Godot 原生 timer )
	await tree.create_timer(seconds, false).timeout
	
	# 3. 核心防御：恢复执行后的生命周期二次校验
	if not is_instance_valid(node):
		return Result.err("Wait 中断: 节点在异步等待期间已被销毁")
		
	return Result.ok()
#endregion
