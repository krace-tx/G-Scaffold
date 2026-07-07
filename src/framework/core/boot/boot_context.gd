class_name BootContext
extends RefCounted

## 启动管线在单次 [method BootPipeline.run] 内的共享上下文。
##
## 由 [BootPipeline] 创建并传给每个 [BootStage.run];Stage 只读/写此处字段,
## 不反向持有 Pipeline。进度 UI 可连接 [signal progress_changed]。

#region Signals
## 某阶段开始执行时发出(在 [method StageRunner.run_stage] 内、await run 之前)。
## [param index] 从 1 起;[param total] 为注册表总 Stage 数;[param stage_name] 见 [method BootStage.get_name]。
signal progress_changed(index: int, total: int, stage_name: String)
#endregion

#region Exports & State
var host: Node                  ## Boot 场景根节点(Bootstrap),Stage 需挂树或取 [code]get_tree()[/code] 时用
var current_index: int = 0      ## 当前遍历下标(0 起),[BootPipeline] 每轮循环写入
var total_stages: int = 0       ## 注册 Stage 总数,用于日志 [code](n/total)[/code] 与进度条
#endregion

#region Lifecycle
func _init(p_host: Node) -> void:
	host = p_host
#endregion
