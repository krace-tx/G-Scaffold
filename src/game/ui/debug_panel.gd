class_name DebugPanel
extends BaseUI

## 调试面板(Debug 层):FPS/内存、场景跳转、存档清除/导出、Bus 事件监视。
##
## 仅开发期使用,通过 App.ui.open(UIIds.DEBUG) 打开(游戏可自行绑定热键如 F3)。
## UI 全程用代码构建(占位工具面板不值得单独维护 .tscn)。KEEP 缓存,反复开关不重建。

#region Constants & Enums
const _MONITOR_MAX_LINES: int = 12   ## Bus 事件监视保留的最近行数
#endregion

#region Exports & State
var _stats_label: Label
var _monitor_label: Label
var _monitor_lines: PackedStringArray = PackedStringArray()
#endregion

#region Lifecycle
func _ready() -> void:
	_build_ui()
	_connect_bus()


func _process(_delta: float) -> void:
	if not visible:
		return
	var mem_mb := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	_stats_label.text = "FPS %d   |   Mem %.1f MB   |   scene: %s" % [
		Engine.get_frames_per_second(), mem_mb, App.scenes.get_current_id(),
	]
#endregion

#region Public API
func _on_open(_params: Dictionary) -> void:
	_refresh_monitor()
#endregion

#region Internal
func _connect_bus() -> void:
	Bus.scene_changed.connect(func(id: StringName) -> void: _log_event("scene_changed: %s" % id))
	Bus.ui_opened.connect(func(id: StringName) -> void: _log_event("ui_opened: %s" % id))
	Bus.ui_closed.connect(func(id: StringName) -> void: _log_event("ui_closed: %s" % id))
	Bus.ad_reward_granted.connect(func(p: StringName) -> void: _log_event("ad_reward_granted: %s" % p))
	Bus.app_paused.connect(func() -> void: _log_event("app_paused"))
	Bus.app_resumed.connect(func() -> void: _log_event("app_resumed"))


func _log_event(line: String) -> void:
	_monitor_lines.append(line)
	while _monitor_lines.size() > _MONITOR_MAX_LINES:
		_monitor_lines.remove_at(0)
	if is_inside_tree():
		_refresh_monitor()


func _refresh_monitor() -> void:
	if _monitor_label != null:
		_monitor_label.text = "Bus events:\n" + "\n".join(_monitor_lines)


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(12, 12)
	add_child(panel)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "— DEBUG PANEL —"
	vbox.add_child(title)

	_stats_label = Label.new()
	vbox.add_child(_stats_label)

	vbox.add_child(_button("→ Main Menu", func() -> void: App.scenes.replace(SceneIds.MAIN_MENU)))
	vbox.add_child(_button("→ Level", func() -> void: App.scenes.replace(SceneIds.LEVEL)))
	vbox.add_child(_button("Clear Save", func() -> void: _clear_save()))
	vbox.add_child(_button("Dump Save → log", func() -> void: App.log.info("debug", App.save.to_json())))
	vbox.add_child(_button("Dump Logs → stdout", func() -> void: print(App.log.dump())))
	vbox.add_child(_button("Close", func() -> void: App.ui.close(UIIds.DEBUG)))

	_monitor_label = Label.new()
	vbox.add_child(_monitor_label)


func _button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(on_press)
	return b


func _clear_save() -> void:
	App.save.wipe()
	App.log.info("debug", "save wiped")
#endregion
