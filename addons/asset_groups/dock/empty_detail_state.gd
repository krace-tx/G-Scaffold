@tool
extends Control

## 详情区空状态占位:叠在统一的 DetailPanel 卡片内,仅切换文案层,
## 背景由外层 [PanelContainer] 的 card_panel 样式统一提供。

@onready var _icon: TextureRect = %Icon
@onready var _title: Label = %Title
@onready var _body: Label = %Body
@onready var _hints: VBoxContainer = %Hints


func setup(
	host: Control,
	icon_name: String,
	title: String,
	body: String,
	hints: PackedStringArray = PackedStringArray()
) -> void:
	if not is_node_ready():
		await ready
	var icon := host.get_theme_icon(icon_name, "EditorIcons")
	if icon != null:
		_icon.texture = icon
	_icon.modulate = Color(1, 1, 1, 0.42)
	_title.text = title
	_body.text = body
	_title.add_theme_color_override("font_color", host.get_theme_color("font_color", "Editor"))
	_title.add_theme_font_size_override("font_size", 15)
	_body.add_theme_color_override("font_color", host.get_theme_color("font_placeholder_color", "Editor"))
	_body.add_theme_font_size_override("font_size", 12)
	_rebuild_hints(host, hints)


func _rebuild_hints(host: Control, hints: PackedStringArray) -> void:
	for child in _hints.get_children():
		child.queue_free()
	var bullet_icon := host.get_theme_icon("ArrowRight", "EditorIcons")
	var hint_color := host.get_theme_color("font_color", "Editor").darkened(0.2)
	for hint in hints:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var bullet := TextureRect.new()
		bullet.custom_minimum_size = Vector2(14, 14)
		bullet.texture = bullet_icon
		bullet.modulate = Color(1, 1, 1, 0.45)
		bullet.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var label := Label.new()
		label.text = hint
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_color_override("font_color", hint_color)
		label.add_theme_font_size_override("font_size", 12)
		row.add_child(bullet)
		row.add_child(label)
		_hints.add_child(row)
