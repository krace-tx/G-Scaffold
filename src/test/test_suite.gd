@abstract
class_name TestSuite
extends RefCounted

## 一个测试集。子类实现 [method id] 与 [method run]；失败不终止后续集。
## 用例走 [method run_case]，结束时 [method outcome] 汇总。

## 单条：[code]{ name: String, passed: bool, detail: String, elapsed_ms: int }[/code]
var cases: Array[Dictionary] = []


@abstract
func id() -> String


## 执行本集。必须是协程：子类里会 [code]await[/code] [method AssetService.load] 等。
func run(_host: Node) -> Result:
	# 基类带 await，TestPipeline 里 await suite.run() 才合法。
	await Engine.get_main_loop().process_frame
	return Result.err("Override TestSuite.run.")


## 跑一条用例并记入 [member cases]。
func run_case(case_name: String, fn: Callable) -> void:
	var started_ms := Time.get_ticks_msec()
	# Callable.call() 静态类型不是协程；运行时 fn 里若有 await 仍必须在此 await。
	@warning_ignore("redundant_await")
	var result: Result = await fn.call()
	record(case_name, result, Time.get_ticks_msec() - started_ms)
	# 真实 await：否则分析器认为本方法不是协程，调用方的 await run_case 也会被误报。
	await Engine.get_main_loop().process_frame


## 记下一条用例。返回 [param result]，方便链式收集。
func record(case_name: String, result: Result, elapsed_ms: int = 0) -> Result:
	var passed := result.is_ok()
	var detail := ""
	if passed:
		detail = "Success: %s" % (String(result.value) if result.value != null else "ok")
	else:
		detail = "Failure: %s" % String(result.error)
	cases.append({
		name = case_name,
		passed = passed,
		detail = detail,
		elapsed_ms = elapsed_ms,
	})
	return result


## 全部通过则 ok，否则 err 带失败用例名。
func outcome() -> Result:
	var names: PackedStringArray = []
	for case in cases:
		if not case.passed:
			names.append(String(case.name))
	if names.is_empty():
		return Result.ok()
	return Result.err("%d case(s) failed: %s." % [names.size(), ", ".join(names)])
