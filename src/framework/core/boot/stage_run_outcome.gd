class_name StageRunOutcome
extends RefCounted

## [StageRunner.run_stage] 的返回值,供 [BootPipeline] 决定是否继续后续阶段。

#region Exports & State
var should_continue: bool = true    ## false 时 Pipeline 终止(FATAL/RETRY);true 则继续(DEGRADE/IGNORE 或成功)
var result: Result = Result.ok()    ## 本阶段 [method BootStage.run] 的原始结果,供重试 UI 或诊断读取
#endregion
