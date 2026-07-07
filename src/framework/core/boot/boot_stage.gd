@abstract
class_name BootStage
extends RefCounted

## 启动管线单个阶段的基础契约。
##
## 子类必须实现 [method get_name] 与 [method run];可选覆盖 [method should_run]、
## [method failure_strategy]。调度/计时/日志/失败策略执行由 [BootPipeline] +
## [StageRunner] 统一负责。详见 [code]docs/architecture/boot-sequence.md[/code]。

#region Constants & Enums
## 启动日志统一 tag,供各 Stage 与 [StageRunner] 打 [code][boot][/code] 日志。
const LOG_TAG: String = "boot"
#endregion

#region Public API
## 阶段标识,用于日志与 [signal BootContext.progress_changed] 的 [param stage_name]。
@abstract
func get_name() -> String


## 是否执行本阶段。默认 true;可按平台或功能开关返回 false —— [BootPipeline] 会跳过,
## 不调用 [method run],也不记失败。
func should_run(_ctx: BootContext) -> bool:
	return true


## [method run] 返回 [code]Result.err[/code] 时 [StageRunner] 的处理方式。
## 默认 [enum BootFailureStrategy.Kind.FATAL](致命,终止管线);子类按业务改为
## [code]RETRY[/code] / [code]DEGRADE[/code] / [code]IGNORE[/code]。
func failure_strategy() -> BootFailureStrategy.Kind:
	return BootFailureStrategy.Kind.FATAL


## 执行阶段逻辑:创建/初始化服务、挂树、预热等。该方法为异步(子类可 [code]await[/code])。
## 成功返回 [method Result.ok],可预期失败返回 [method Result.err] 并由
## [method failure_strategy] 决定后续行为。
@abstract
func run(_ctx: BootContext) -> Result
#endregion
