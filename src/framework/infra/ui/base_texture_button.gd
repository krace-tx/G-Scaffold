class_name BaseTextureButton
extends TextureButton

## 贴图按钮基类。按压缩放、点击音效、振动；参数可在检查器改，不填则用默认。
## 做：按下/抬起/滑出时的缩放，以及 [signal pressed] 时的音效与振动。
## 不做：换场、广告、业务回调；那些由场景脚本连 [signal pressed]。

#region Constants
const _DEFAULT_SFX_PATH: String = "res://src/assets/audio/sfx/sfx_ui_button_click.wav"
#endregion

#region Exports
@export_group("Scale")
## 按下时的缩放。大于 1 外扩，小于 1 内缩。
@export var press_scale: float = 1.05
## 抬起 / 滑出后回到的缩放。
@export var idle_scale: float = 1.0
## 缩放补间时长（秒）。
@export var scale_duration: float = 0.1

@export_group("Feedback")
## 点击时是否播音效。
@export var play_sfx: bool = true
## 点击音效路径。空则跳过，即使 [member play_sfx] 开着。
@export_file("*.wav") var sfx_path: String = _DEFAULT_SFX_PATH
## 点击音效音量（分贝）。[method AudioService.play_sfx_by_path] 的 volume。
@export var sfx_volume_db: int = 0
## 点击时是否振动。
@export var play_vibrate: bool = true
#endregion

#region State
var _tween: Tween = null
#endregion


#region Lifecycle
func _ready() -> void:
	pivot_offset = size * 0.5
	resized.connect(func(): pivot_offset = size * 0.5)

	button_down.connect(_on_base_button_down)
	button_up.connect(_on_base_button_up)
	mouse_exited.connect(_on_base_mouse_exited)
	pressed.connect(_on_base_pressed)
#endregion


#region Internal
func _scale_to(to_scale: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(to_scale, to_scale), scale_duration) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)


func _on_base_button_down() -> void:
	_scale_to(press_scale)


func _on_base_button_up() -> void:
	_scale_to(idle_scale)


func _on_base_mouse_exited() -> void:
	_scale_to(idle_scale)


func _on_base_pressed() -> void:
	if play_sfx and not sfx_path.is_empty() and App.audio:
		App.audio.play_sfx_by_path(sfx_path, sfx_volume_db)
	if play_vibrate:
		VibrateUtils.vibrate()
#endregion
