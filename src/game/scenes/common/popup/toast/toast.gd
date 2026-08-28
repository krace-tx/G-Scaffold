class_name Toast
extends Control

## 轻量级浮层提示组件 (Toast)。
## 自动在屏幕顶部/居中淡入淡出。

@onready var _label: Label = $Panel/Margin/Label

func setup(msg: String, duration: float = 1.5) -> void:
	_label.text = msg
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.tween_interval(duration)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
