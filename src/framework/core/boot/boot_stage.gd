@abstract
class_name BootStage
extends RefCounted

## 启动管线单个阶段。
## 子类实现 [method id] 与 [method run]；失败时默认终止管线。

enum Failure {
	STOP,      ## 记 error，终止后续阶段
	CONTINUE,  ## 记 warn，继续后续阶段（SDK 等可降级场景）
}

## 阶段标识，用作日志 tag 与进度输出。
@abstract
func id() -> String


## 本阶段 [method run] 失败时怎么走。默认 STOP。
func on_fail() -> Failure:
	return Failure.STOP


## 阶段进度权重（默认 1.0；耗时长的阶段如资源下载可配置为更高权重以分配更多进度条比例）。
func weight() -> float:
	return 1.0


## 执行本阶段。成功 [method Result.ok]，可预期失败 [method Result.err]。
## [param on_progress] 为阶段内部进度汇报回调（签名 [code]func(ratio: float)[/code]，0.0 ~ 1.0）。
## 基类带 await，[method BootPipeline.run] 里 await stage.run() 才合法；子类可再 await。
func run(_on_progress: Callable = Callable()) -> Result:
	await Engine.get_main_loop().process_frame
	return Result.err("Override BootStage.run.")


## 以 [method id] 为 tag 打日志。
## boot 创建 [member App.log] 之前走 print，避免启动首条日志丢失。
## 不叫 log：会遮蔽全局自然对数 [method @GlobalScope.log]。
func info(message: String) -> void:
	_emit(LogService.LogLevel.INFO, message)


func warn(message: String) -> void:
	_emit(LogService.LogLevel.WARN, message)


func error(message: String) -> void:
	_emit(LogService.LogLevel.ERROR, message)


func _emit(level: LogService.LogLevel, message: String) -> void:
	var tag := id()
	if App.log == null:
		LogService.print_raw(level, tag, message)
		return

	match level:
		LogService.LogLevel.ERROR:
			App.log.error(tag, message)
		LogService.LogLevel.WARN:
			App.log.warn(tag, message)
		_:
			App.log.info(tag, message)
