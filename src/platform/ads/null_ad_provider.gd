class_name NullAdProvider
extends AdProvider

## 广告的 Null 实现。**不是测试专用品,是日常开发体验的核心**:编辑器 F5 能完整
## 跑通"请求 → 观看 → 发奖"全流程,不依赖真机;SDK 初始化失败时也降级到这里,
## 保证广告挂了游戏照常能玩。见 ADR-0004。

#region Constants & Enums
const _SIMULATED_WATCH: float = 1.0   ## 模拟观看时长(秒)
#endregion

#region Public API
func initialize() -> bool:
	App.log.info("ads", "null ad provider initialized (editor/unsupported/degraded)")
	return true


func show_rewarded(placement: StringName) -> AdResult:
	App.log.info("ads", "null rewarded '%s' — simulating %.0fs watch" % [placement, _SIMULATED_WATCH])
	await App.get_tree().create_timer(_SIMULATED_WATCH).timeout
	return AdResult.rewarded()


func is_ready(_placement: StringName) -> bool:
	return true
#endregion
