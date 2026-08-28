class_name ExampleSetting
extends Control

## 脚手架通用设置弹窗。
## 演示 SettingManager 双向绑定（音乐、音效、振动开关）。

@onready var _dimmer: ColorRect = $Dimmer
@onready var _close_btn: Button = $Panel/VBox/Header/CloseBtn
@onready var _music_check: CheckBox = $Panel/VBox/Options/MusicRow/MusicCheck
@onready var _sfx_check: CheckBox = $Panel/VBox/Options/SfxRow/SfxCheck
@onready var _vibrate_check: CheckBox = $Panel/VBox/Options/VibrateRow/VibrateCheck

func _ready() -> void:
	_close_btn.pressed.connect(_close)
	_dimmer.gui_input.connect(_on_dimmer_gui_input)
	
	var setting := Game.setting if Game.setting != null else SettingManager.new()
	
	_music_check.set_pressed_no_signal(setting.music_on)
	_sfx_check.set_pressed_no_signal(setting.sfx_on)
	_vibrate_check.set_pressed_no_signal(setting.vibrate_on)
	
	_music_check.toggled.connect(func(val: bool):
		if Game.setting != null:
			Game.setting.music_on = val
		App.log.debug("ExampleSetting", "Music toggled -> %s" % val)
	)
	
	_sfx_check.toggled.connect(func(val: bool):
		if Game.setting != null:
			Game.setting.sfx_on = val
		App.log.debug("ExampleSetting", "SFX toggled -> %s" % val)
	)
	
	_vibrate_check.toggled.connect(func(val: bool):
		if Game.setting != null:
			Game.setting.vibrate_on = val
			if val:
				Game.setting.vibrate(30)
		App.log.debug("ExampleSetting", "Vibrate toggled -> %s" % val)
	)


func _close() -> void:
	NodeUtils.safe_free(self)


func _on_dimmer_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		_close()
