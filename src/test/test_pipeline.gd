class_name TestPipeline
extends RefCounted

## 按序执行 [TestSuite]。先跑 [method BootPipeline.app_launch_stages]，一集失败记下来并继续。

var _suites: Array[TestSuite] = []


func _init(suites: Array[TestSuite]) -> void:
	_suites = suites


func run(host: Node) -> Result:
	# 测试场景也会走 Autoload [method App.bootstrap]；这里 await 等到管线结束。
	await App.bootstrap()
	if App.log == null:
		_emit("Boot failed.")
		return Result.err("Boot failed.")

	var failed := 0
	var total := _suites.size()
	for i in total:
		var suite: TestSuite = _suites[i]
		suite.cases.clear()
		_emit("Start %s (%d/%d)" % [suite.id(), i + 1, total])
		var started_ms := Time.get_ticks_msec()
		var result: Result = await suite.run(host)
		var elapsed_ms := Time.get_ticks_msec() - started_ms
		for case in suite.cases:
			_emit("  %s (%dms) %s" % [String(case.name), int(case.elapsed_ms), String(case.detail)])
		if result.is_ok():
			_emit("PASS %s (%dms)" % [suite.id(), elapsed_ms])
		else:
			failed += 1
			_emit("FAIL %s (%dms) — %s" % [suite.id(), elapsed_ms, result.error])

	if failed == 0:
		_emit("All suites passed (%d)." % total)
		return Result.ok()
	_emit("Failed %d/%d." % [failed, total])
	return Result.err("Failed %d/%d." % [failed, total])


func _emit(message: String) -> void:
	if App.log:
		App.log.debug("TestPipeline", message)
	else:
		print("[TestPipeline] %s" % message)
