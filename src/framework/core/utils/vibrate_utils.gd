class_name VibrateUtils
extends RefCounted

## 设备振动。只问总开关，再调引擎马达。
## 做：一次短振，或按 [振, 停, 振, …] 毫秒序列播放。设置页把 [member enabled] 设成玩家选择即可。
## 不做：镜头抖动、补间、读存档；开关由调用方（设置）写入。

## 玩家总开关。关则 [method vibrate] / [method pattern] 空操作。默认开，设置尚未落盘时也不误关。
static var enabled: bool = true

## 按钮轻振：15ms。
const LIGHT: Array[int] = [15]
## 连续两下：振 100ms、停 50ms、再振 100ms。
const HEAVY: Array[int] = [100, 50, 100]

static var _token: int = 0

#region Public API
## 触发一次设备振动。[br]
## [param duration_ms] 持续毫秒。默认 15。小于等于 0，或 [member enabled] 为 [code]false[/code] 时不振。
static func vibrate(duration_ms: int = 15) -> void:
	pattern([duration_ms])


## 按模式振动。[br]
## [param steps] 毫秒序列，偶数下标是振动时长，奇数下标是间隔（不振）。例如 [code][100, 50, 100][/code] 为振、停、再振。[br]
## 空数组、[member enabled] 为 [code]false[/code] 时不振。再次调用会打断尚未播完的上一段。
static func pattern(steps: Array[int]) -> void:
	if not enabled or steps.is_empty():
		return
	_token += 1
	_play(steps, 0, _token)
#endregion

#region Internal
static func _play(steps: Array[int], index: int, token: int) -> void:
	if token != _token or not enabled or index >= steps.size():
		return
	var duration_ms: int = steps[index]
	if duration_ms > 0:
		Input.vibrate_handheld(duration_ms)
	if index + 1 >= steps.size():
		return
	var gap_ms: int = steps[index + 1]
	if gap_ms <= 0:
		_play(steps, index + 2, token)
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	tree.create_timer(gap_ms / 1000.0).timeout.connect(
		_play.bind(steps, index + 2, token),
		CONNECT_ONE_SHOT
	)
#endregion
