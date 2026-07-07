class_name BootPipeline
extends RefCounted

## 启动管线调度器:按序执行 [BootStage] 列表,委托 [StageRunner] 处理单步。
##
## [code]Bootstrap[/code] 在 [code]_ready[/code] 里 [code]new(self, default_stages())[/code]
## 并 [code]await run()[/code]。新增阶段:实现 [BootStage] 子类并插入 [method default_stages]。

#region Exports & State
var _ctx: BootContext                           ## 本次 run 的共享上下文,构造时绑定 [param p_host]
var _stages: Array[BootStage] = []              ## 待执行阶段(顺序即依赖顺序),构造时注入
var _runner: StageRunner = StageRunner.new()    ## 无状态执行器,负责单阶段计时/日志/失败策略
#endregion

#region Lifecycle
func _init(p_host: Node, p_stages: Array[BootStage]) -> void:
	_stages = p_stages
	_ctx = BootContext.new(p_host)
	_ctx.total_stages = _stages.size()
#endregion

#region Public API
## 返回项目默认启动阶段列表;修改此表即调整启动顺序与内容。
static func default_stages() -> Array[BootStage]:
	return [
		LogStage.new(),            # 日志服务
		CoreServiceStage.new(),    # 场景 / UI / 资产 / 音频服务挂树
		LocalConfigStage.new(),    # 时间源与本地配置
		SaveStage.new(),           # 存档加载(失败可重试)
		PlatformStage.new(),       # 平台 SDK(失败降级)
		NetworkStage.new(),        # 登录与远程配置(失败降级)
		AssetStage.new(),          # 预热常驻资产
		EnterGameStage.new(),      # 进入主菜单
	]


## 顺序调度 [member _stages]。该方法为异步。
## [method BootStage.should_run] 为 false 时跳过;[member StageRunOutcome.should_continue]
## 为 false 时提前结束(致命/重试失败),不再执行后续 Stage。
func run() -> void:
	for i in _stages.size():
		var stage: BootStage = _stages[i]
		_ctx.current_index = i
		if not stage.should_run(_ctx):
			_log_skip(stage)
			continue

		var outcome: StageRunOutcome = await _runner.run_stage(stage, _ctx)
		if not outcome.should_continue:
			return
#endregion

#region Internal
func _log_skip(stage: BootStage) -> void:
	if App.log:
		App.log.info(BootStage.LOG_TAG, "stage skipped: %s" % stage.get_name())
#endregion
