class_name BootFailureStrategy
extends RefCounted

## 启动阶段失败时 [StageRunner] 的行为枚举。
##
## 由各 [BootStage.failure_strategy] 声明;[StageRunner._apply_failure] 读取并执行。
## 策略含义见 [code]docs/architecture/boot-sequence.md[/code]。

#region Constants & Enums
enum Kind {
	FATAL,      ## 记 error,[member StageRunOutcome.should_continue] = false,终止管线
	RETRY,      ## 记 error,终止管线;预期由 UI 重新调用 [method BootPipeline.run]
	DEGRADE,    ## 记 warn,继续后续 Stage(第三方/SDK 类场景常用)
	IGNORE,     ## 记 info,继续后续 Stage
}
#endregion
