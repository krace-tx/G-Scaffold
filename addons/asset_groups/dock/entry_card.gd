@tool
extends PanelContainer

## 「组件库」里的最小单元:一张卡片,渲染并编辑**一条**清单条目。
##
## 完全由外部传入的字段 schema 驱动(见 [method setup]),自己不认识 scene/ui/asset
## 三种类型的差异——三种条目的差异全部落在各自的 schema 里,卡片只按 schema 铺字段。
## 这样新增一类条目或给某类加字段,都不用改本文件。

#region Signals
## 任一字段被用户改动后发出(值已写回 entry),供上层刷新标题计数、标脏等。
signal changed
## 用户点了删除按钮,携带要删除的 [param entry],由上层从数组里移除并重建列表。
signal removed(entry: Resource)
## 用户点了某个路径字段的「浏览」按钮,请求上层弹出资源选择框。
## [param entry] 是本条目,[param key] 是要写入的属性名,[param filters] 是文件过滤器。
signal browse_requested(entry: Resource, key: String, filters: PackedStringArray)
#endregion

#region Constants & Enums
## 字段渲染类型:纯文本 id、资源路径(带浏览按钮)、StringName 分组、枚举下拉。
enum Field { ID, PATH, GROUP, ENUM }
#endregion

#region Exports & State
var _entry: Resource
var _schema: Array = []
## key(String)→ 该字段的输入控件,[method refresh] 用它把外部改动同步回界面。
var _inputs: Dictionary = {}
#endregion

#region Public API
## 用 [param entry] 与字段 [param schema] 初始化卡片并铺出所有字段。
## schema 每项为字典:{key, label, kind, filters?(PATH 用), options?(ENUM 用的 name→value 字典)}。
func setup(entry: Resource, schema: Array) -> void:
	_entry = entry
	_schema = schema
	_build()


## 把 entry 的当前值重新灌回各输入控件(外部改了 entry 后调用,如浏览选完路径)。
func refresh() -> void:
	for key: String in _inputs:
		var field := _find_field(key)
		var control: Control = _inputs[key]
		if field["kind"] == Field.ENUM:
			(control as OptionButton).select((control as OptionButton).get_item_index(_entry.get(key)))
		else:
			(control as LineEdit).text = String(_entry.get(key))
#endregion

#region Internal
func _build() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	for field: Dictionary in _schema:
		row.add_child(_build_field(field))
	row.add_child(_build_remove_button())


## 每个字段渲染成「小标签 + 输入控件」的竖直一格,便于横向排列成一行。
func _build_field(field: Dictionary) -> Control:
	var cell := VBoxContainer.new()
	cell.add_theme_constant_override("separation", 2)
	var label := Label.new()
	label.text = field["label"]
	label.add_theme_font_size_override("font_size", 10)
	label.modulate = Color(1, 1, 1, 0.55)
	cell.add_child(label)

	var control := _build_input(field)
	_inputs[field["key"]] = _input_of(control)
	cell.add_child(control)
	return cell


## PATH 字段是「LineEdit + 浏览按钮」的组合,取输入控件时要拿里面的 LineEdit。
func _input_of(control: Control) -> Control:
	if control is HBoxContainer:
		return control.get_child(0)
	return control


func _build_input(field: Dictionary) -> Control:
	match int(field["kind"]):
		Field.ENUM:
			return _build_enum(field)
		Field.PATH:
			return _build_path(field)
		_:
			return _build_line(field)


func _build_line(field: Dictionary) -> LineEdit:
	var key: String = field["key"]
	var edit := LineEdit.new()
	edit.text = String(_entry.get(key))
	edit.custom_minimum_size.x = 130 if field["kind"] == Field.ID else 90
	edit.placeholder_text = field.get("placeholder", "")
	edit.text_changed.connect(func(text: String) -> void:
		_entry.set(key, StringName(text) if _is_string_name(key) else text)
		changed.emit())
	return edit


func _build_path(field: Dictionary) -> HBoxContainer:
	var key: String = field["key"]
	var filters: PackedStringArray = field.get("filters", PackedStringArray(["*"]))
	var box := HBoxContainer.new()
	var edit := LineEdit.new()
	edit.text = String(_entry.get(key))
	edit.custom_minimum_size.x = 260
	edit.text_changed.connect(func(text: String) -> void:
		_entry.set(key, text)
		changed.emit())
	box.add_child(edit)
	var browse := Button.new()
	browse.text = "…"
	browse.tooltip_text = "浏览选择资源"
	browse.pressed.connect(func() -> void: browse_requested.emit(_entry, key, filters))
	box.add_child(browse)
	return box


func _build_enum(field: Dictionary) -> OptionButton:
	var key: String = field["key"]
	var options: Dictionary = field["options"]
	var opt := OptionButton.new()
	for name: String in options:
		opt.add_item(name.capitalize())
		opt.set_item_id(opt.item_count - 1, options[name])
	opt.select(opt.get_item_index(int(_entry.get(key))))
	opt.item_selected.connect(func(index: int) -> void:
		_entry.set(key, opt.get_item_id(index))
		changed.emit())
	return opt


func _build_remove_button() -> Button:
	var remove := Button.new()
	remove.text = "✕"
	remove.tooltip_text = "删除此条目"
	remove.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	remove.pressed.connect(func() -> void: removed.emit(_entry))
	return remove


func _find_field(key: String) -> Dictionary:
	for field: Dictionary in _schema:
		if field["key"] == key:
			return field
	return {}


## id 与 group 在数据模型里是 StringName,写回时要转类型;path/scene_path 是 String。
func _is_string_name(key: String) -> bool:
	return _find_field(key)["kind"] != Field.PATH
#endregion
