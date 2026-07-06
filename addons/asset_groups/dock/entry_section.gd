@tool
extends VBoxContainer

## 「组件库」里的一个分区:管理**一类**条目(全部 Scenes / 全部 UIs / 全部 Assets)。
##
## 头部有折叠开关、计数标题、「新建」「快速载入」按钮;下面是一列 [EntryCard]。
## 支持从编辑器 FileSystem 面板直接拖资源进来批量登记(见 [method _drop_data])。
## 三个分区共用同一份脚本,差异只在 setup 传入的 schema / 工厂 / 过滤器。

#region Signals
## 本分区数据有任何变化(增删条目、字段编辑),冒泡给面板用于标脏。
signal changed
## 用户请求「快速载入」,由面板弹出共享的资源选择框(携带本分区自身)。
signal quick_load_requested(section: Object)
## 某张卡片请求浏览资源路径,冒泡给面板处理(面板持有共享选择框)。
signal card_browse_requested(entry: Resource, key: String, filters: PackedStringArray)
#endregion

#region Exports & State
var _entries: Array           ## 直接引用 manifest 里的某个数组(scenes/uis/assets),就地增删
var _schema: Array = []
var _path_key: String = ""    ## 该类条目里代表资源路径的属性名(scene_path / path)
var _factory: Callable        ## 新建一个空条目 Resource 的工厂
var _filters: PackedStringArray = PackedStringArray(["*"])
var _exts: PackedStringArray = PackedStringArray()  ## 允许拖入的扩展名(不含点),空 = 全部

var _title: String = ""
var _title_button: Button
var _cards: VBoxContainer
#endregion

#region Public API
## 初始化分区。[param entries] 是 manifest 里的目标数组(按引用就地编辑);
## [param factory] 返回一个新的空条目;[param exts] 限定可拖入的扩展名(空表示不限)。
func setup(p_title: String, entries: Array, schema: Array, path_key: String, factory: Callable,
		filters: PackedStringArray, exts: PackedStringArray) -> void:
	_title = p_title
	_entries = entries
	_schema = schema
	_path_key = path_key
	_factory = factory
	_filters = filters
	_exts = exts
	_build_header()
	_cards = VBoxContainer.new()
	add_child(_cards)
	_build_drop_hint()
	rebuild()


## 清空并按 [member _entries] 重新铺卡片,同时刷新标题计数。
func rebuild() -> void:
	for child in _cards.get_children():
		child.queue_free()
	for entry: Resource in _entries:
		_cards.add_child(_make_card(entry))
	_title_button.text = "%s  (%d)" % [_title, _entries.size()]


## 从一批资源路径批量登记(快速载入 / 拖拽共用)。id 自动由文件名派生(snake_case),
## path 自动注入;已存在相同路径的条目跳过,避免重复登记。
func add_from_files(paths: PackedStringArray) -> void:
	var added := false
	for path in paths:
		if _exts.size() > 0 and not _exts.has(path.get_extension().to_lower()):
			continue
		if _has_path(path):
			continue
		var entry: Resource = _factory.call()
		entry.set(_path_key, path)
		entry.id = StringName(path.get_file().get_basename().to_snake_case())
		_entries.append(entry)
		added = true
	if added:
		rebuild()
		changed.emit()
#endregion

#region Internal
func _build_header() -> void:
	var header := HBoxContainer.new()
	_title_button = Button.new()
	_title_button.flat = true
	_title_button.toggle_mode = true
	_title_button.button_pressed = true
	_title_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_button.toggled.connect(func(on: bool) -> void: _cards.visible = on)
	header.add_child(_title_button)

	var add_btn := Button.new()
	add_btn.text = "＋ 新建"
	add_btn.pressed.connect(_on_add_pressed)
	header.add_child(add_btn)

	var load_btn := Button.new()
	load_btn.text = "⤓ 快速载入"
	load_btn.tooltip_text = "选择资源文件,自动注入 id 与 path"
	load_btn.pressed.connect(func() -> void: quick_load_requested.emit(self))
	header.add_child(load_btn)
	add_child(header)


## 一条淡色提示,兼作醒目的拖拽落点(拖资源到分区任意空白处都能落,这只是视觉提示)。
func _build_drop_hint() -> void:
	var hint := Label.new()
	hint.text = "  ↳ 可从 FileSystem 面板拖拽资源到此批量登记"
	hint.add_theme_font_size_override("font_size", 10)
	hint.modulate = Color(1, 1, 1, 0.35)
	add_child(hint)


func _make_card(entry: Resource) -> Control:
	var card: PanelContainer = preload("entry_card.gd").new()
	card.setup(entry, _schema)
	card.changed.connect(func() -> void: changed.emit())
	card.removed.connect(_on_card_removed)
	card.browse_requested.connect(func(e: Resource, key: String, filters: PackedStringArray) -> void:
		card_browse_requested.emit(e, key, filters))
	return card


func _on_add_pressed() -> void:
	_entries.append(_factory.call())
	rebuild()
	changed.emit()


func _on_card_removed(entry: Resource) -> void:
	_entries.erase(entry)
	rebuild()
	changed.emit()


func _has_path(path: String) -> bool:
	for entry: Resource in _entries:
		if String(entry.get(_path_key)) == path:
			return true
	return false


## 拖拽支持:接受编辑器 FileSystem 的文件拖拽({"type":"files", "files":[...]})。
func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("type") == "files"


func _drop_data(_pos: Vector2, data: Variant) -> void:
	add_from_files(PackedStringArray(data["files"]))
#endregion
