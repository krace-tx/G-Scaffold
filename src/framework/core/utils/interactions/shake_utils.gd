class_name ShakeUtils
extends RefCounted


#region 公共接口 - 预设震动
## 按钮点击时的轻震动
static func shake_button() -> void:
	vibrate_pattern([15])


## 轻度震动
static func shake_light() -> void:
	vibrate_pattern([15])


## 重度震动（连续脉冲）
static func shake_heavy() -> void:
	vibrate_pattern([100, 50, 100])


## 自定义时长的单次震动
static func shake(duration_ms: int = 100) -> void:
	vibrate_pattern([duration_ms])
#endregion


#region 公共接口 - 自定义模式
## 按模式序列震动，pattern 为 [震动毫秒, 间隔毫秒, ...]
static func vibrate_pattern(pattern: Array) -> void:
	for i in range(0, pattern.size(), 2):
		var duration_ms: int = pattern[i]
		Input.vibrate_handheld(duration_ms)
		if i + 1 < pattern.size():
			await App.get_tree().create_timer(pattern[i + 1] / 1000.0).timeout
#endregion
