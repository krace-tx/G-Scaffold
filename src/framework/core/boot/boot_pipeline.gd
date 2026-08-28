class_name BootPipeline
extends RefCounted

## 按序执行 [BootStage]。失败按阶段声明的策略决定是否继续。

var _stages: Array[BootStage] = []


func _init(p_stages: Array[BootStage]) -> void:
	_stages = p_stages


## 默认启动阶段。跳过某阶段 = 不要放进这个列表。
static func app_launch_stages() -> Array[BootStage]:
	return [
		CoreServiceStage.new(),
	]


## 顺序 await 各阶段。支持可选进度回调 [param on_progress]（签名 [code]func(value: float)[/code]，0.0 ~ 100.0）。
## 成功返回 [method Result.ok]，STOP 失败则返回 [method Result.err]。
func run(on_progress: Callable = Callable()) -> Result:
	var total := _stages.size()
	if total == 0:
		_report(on_progress, 100.0)
		return Result.ok()

	# 1. 汇总所有阶段的总权重
	var total_weight := 0.0
	for stage in _stages:
		total_weight += maxf(stage.weight(), 0.01)

	# 2. 依次执行各阶段并按权重分配全局进度区间
	var current_accumulated_weight := 0.0
	for i in total:
		var stage: BootStage = _stages[i]
		var stage_weight := maxf(stage.weight(), 0.01)
		var start_pct := (current_accumulated_weight / total_weight) * 100.0
		var end_pct := ((current_accumulated_weight + stage_weight) / total_weight) * 100.0

		# 构造当前阶段的细粒度子进度映射闭包（0.0 ~ 1.0 -> start_pct ~ end_pct）
		var sub_reporter := func(ratio: float) -> void:
			var mapped_pct := lerpf(start_pct, end_pct, clampf(ratio, 0.0, 1.0))
			_report(on_progress, mapped_pct)

		_report(on_progress, start_pct)

		var started_ms := Time.get_ticks_msec()
		stage.info("Start (%d/%d, weight=%.1f)" % [i + 1, total, stage_weight])

		var result: Result = await stage.run(sub_reporter)
		var elapsed_ms := Time.get_ticks_msec() - started_ms
		if result.is_ok():
			stage.info("Done (%dms)" % elapsed_ms)
			_report(on_progress, end_pct)
			current_accumulated_weight += stage_weight
			continue

		if not _on_failure(stage, result, elapsed_ms):
			return result

		current_accumulated_weight += stage_weight

	_report(on_progress, 100.0)
	return Result.ok()


## 返回 true = 管线继续；false = 终止。
func _on_failure(stage: BootStage, result: Result, elapsed_ms: int) -> bool:
	var msg := "Failed (%dms) — %s" % [elapsed_ms, result.error]
	if stage.on_fail() == BootStage.Failure.CONTINUE:
		stage.warn(msg)
		return true
	stage.error(msg)
	return false


static func _report(on_progress: Callable, value: float) -> void:
	if on_progress.is_valid():
		on_progress.call(value)
