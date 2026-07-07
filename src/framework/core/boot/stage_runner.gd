class_name StageRunner
extends RefCounted

## 单阶段执行器:包装 [method BootStage.run],统一打日志、计耗时、应用 [BootFailureStrategy]。
##
## 不持有管线状态;每次 [method run_stage] 独立,[BootPipeline] 复用同一实例即可。

#region Constants & Enums
enum _LogLevel { INFO, WARN, ERROR }    ## 映射到 [LogService] 对应级别
#endregion

#region Public API
## 执行 [param stage] 并返回结果。该方法为异步。
## 成功时 [member StageRunOutcome.should_continue] 恒为 true;失败时按
## [method BootStage.failure_strategy] 决定是否终止管线。
func run_stage(stage: BootStage, ctx: BootContext) -> StageRunOutcome:
	var outcome := StageRunOutcome.new()
	var stage_name := stage.get_name()
	var started_ms := Time.get_ticks_msec()

	_log(_LogLevel.INFO, "stage start: %s (%d/%d)" % [stage_name, ctx.current_index + 1, ctx.total_stages])
	ctx.progress_changed.emit(ctx.current_index + 1, ctx.total_stages, stage_name)

	var result: Result = await stage.run(ctx)
	outcome.result = result
	var elapsed_ms := Time.get_ticks_msec() - started_ms

	if result.is_ok():
		_log(_LogLevel.INFO, "stage done: %s (%dms)" % [stage_name, elapsed_ms])
		return outcome

	return _apply_failure(stage, result, elapsed_ms, outcome)
#endregion

#region Internal
# 按 Stage 声明的失败策略写日志,并在 FATAL/RETRY 时置 should_continue = false。
func _apply_failure(stage: BootStage, result: Result, elapsed_ms: int, outcome: StageRunOutcome) -> StageRunOutcome:
	var stage_name := stage.get_name()
	var reason := String(result.error)

	match stage.failure_strategy():
		BootFailureStrategy.Kind.FATAL:
			_log(_LogLevel.ERROR, "stage failed (fatal): %s (%dms) — %s" % [stage_name, elapsed_ms, reason])
			outcome.should_continue = false
		BootFailureStrategy.Kind.RETRY:
			_log(_LogLevel.ERROR, "stage failed (retry): %s (%dms) — %s" % [stage_name, elapsed_ms, reason])
			outcome.should_continue = false
		BootFailureStrategy.Kind.DEGRADE:
			_log(_LogLevel.WARN, "stage failed (degrade): %s (%dms) — %s" % [stage_name, elapsed_ms, reason])
		BootFailureStrategy.Kind.IGNORE:
			_log(_LogLevel.INFO, "stage failed (ignore): %s (%dms) — %s" % [stage_name, elapsed_ms, reason])

	return outcome


# LogStage 之前 App.log 尚不存在,回退 print 避免启动首条日志丢失。
func _log(level: _LogLevel, message: String) -> void:
	if App.log:
		match level:
			_LogLevel.ERROR:
				App.log.error(BootStage.LOG_TAG, message)
			_LogLevel.WARN:
				App.log.warn(BootStage.LOG_TAG, message)
			_:
				App.log.info(BootStage.LOG_TAG, message)
	else:
		print("[", BootStage.LOG_TAG, "] ", message)
#endregion
