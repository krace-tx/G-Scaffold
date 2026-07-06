@tool
extends VBoxContainer

## Asset Groups 面板:类 Unity Addressable Group 的可视化资源清单编辑器。
##
## 按类型分三个分区(Scenes / UIs / Assets),每个分区一列卡片式条目,支持「快速载入」
## 与从 FileSystem 拖拽批量登记(id/path 自动注入)。顶部可配置导出位置,「导出」时把
## 内存里的 [AssetManifest] 落成 asset_manifest.tres 并重写 SceneIds/UIIds/AssetIds。
##
## 面板只做「收集输入 + 编排」,真正的读写/代码生成在 [code]manifest_io.gd[/code]。

#region Constants & Enums
const ManifestIO := preload("../manifest_io.gd")
const Section := preload("entry_section.gd")
const Card := preload("entry_card.gd")

## 导出位置默认值(可在面板里改)。刻意不引用 ResPaths,让插件目录整体可移植。
const _DEFAULT_MANIFEST: String = "res://src/resource/data/asset_manifest.tres"
const _DEFAULT_IDS_DIR: String = "res://src/resource/scripts"

## 编辑器项目元数据的存放键,用来记住用户上次填的导出位置。
const _META_SECTION: String = "asset_groups"
#endregion

#region Exports & State
var _manifest: AssetManifest
var _sections: Array = []

var _manifest_edit: LineEdit
var _ids_edit: LineEdit
var _status: Label
var _dialog: EditorFileDialog
var _scroll_ref: ScrollContainer   ## 当前的分区滚动容器,重载时整个换掉
## 文件框回调的上下文:{type, ...}。type ∈ quick_load / card_path / manifest / ids_dir。
var _pending: Dictionary = {}
#endregion

#region Lifecycle
func _ready() -> void:
	_build_toolbar()
	_build_export_bar()
	add_child(HSeparator.new())
	_build_dialog()
	_load_paths_from_meta()
	_reload()
#endregion

#region Internal — UI 构建
func _build_toolbar() -> void:
	var bar := HBoxContainer.new()
	var title := Label.new()
	title.text = "📦 Asset Groups"
	title.add_theme_font_size_override("font_size", 15)
	bar.add_child(title)
	bar.add_child(_spacer())

	var reload_btn := Button.new()
	reload_btn.text = "↻ 重载"
	reload_btn.tooltip_text = "丢弃未导出的改动,从磁盘重新读取清单"
	reload_btn.pressed.connect(_reload)
	bar.add_child(reload_btn)

	var export_btn := Button.new()
	export_btn.text = "✔ 导出"
	export_btn.tooltip_text = "写出 asset_manifest.tres 并重新生成 Ids 常量类"
	export_btn.pressed.connect(_on_export)
	bar.add_child(export_btn)

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 11)
	bar.add_child(_status)
	add_child(bar)


func _build_export_bar() -> void:
	var grid := GridContainer.new()
	grid.columns = 3
	_manifest_edit = _path_row(grid, "清单输出 (.tres):", _DEFAULT_MANIFEST,
		func() -> void: _open_dialog({"type": "manifest"}, EditorFileDialog.FILE_MODE_SAVE_FILE, PackedStringArray(["*.tres"])))
	_ids_edit = _path_row(grid, "Ids 输出目录:", _DEFAULT_IDS_DIR,
		func() -> void: _open_dialog({"type": "ids_dir"}, EditorFileDialog.FILE_MODE_OPEN_DIR, PackedStringArray()))
	add_child(grid)


func _path_row(grid: GridContainer, label_text: String, default: String, on_browse: Callable) -> LineEdit:
	var label := Label.new()
	label.text = label_text
	grid.add_child(label)
	var edit := LineEdit.new()
	edit.text = default
	edit.custom_minimum_size.x = 360
	grid.add_child(edit)
	var browse := Button.new()
	browse.text = "浏览…"
	browse.pressed.connect(on_browse)
	grid.add_child(browse)
	return edit


func _build_sections() -> void:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	add_child(scroll)
	scroll.size_flags_stretch_ratio = 1.0

	_sections = []
	_add_section(box, "Scenes", _manifest.scenes, _scene_schema(), "scene_path",
		func() -> Resource: return SceneEntry.new(), PackedStringArray(["*.tscn"]), PackedStringArray(["tscn"]))
	box.add_child(HSeparator.new())
	_add_section(box, "UIs", _manifest.uis, _ui_schema(), "scene_path",
		func() -> Resource: return UIEntry.new(), PackedStringArray(["*.tscn"]), PackedStringArray(["tscn"]))
	box.add_child(HSeparator.new())
	_add_section(box, "Assets", _manifest.assets, _asset_schema(), "path",
		func() -> Resource: return AssetEntry.new(), PackedStringArray(["*"]), PackedStringArray())
	_scroll_ref = scroll


func _add_section(box: VBoxContainer, title: String, entries: Array, schema: Array, path_key: String,
		factory: Callable, filters: PackedStringArray, exts: PackedStringArray) -> void:
	var section: VBoxContainer = Section.new()
	box.add_child(section)
	section.setup(title, entries, schema, path_key, factory, filters, exts)
	section.quick_load_requested.connect(_on_quick_load)
	section.card_browse_requested.connect(_on_card_browse)
	section.changed.connect(_on_dirty)
	_sections.append(section)
#endregion

#region Internal — 字段 schema
func _scene_schema() -> Array:
	return [
		{"key": "id", "label": "ID", "kind": Card.Field.ID, "placeholder": "scene_id"},
		{"key": "scene_path", "label": "场景 (.tscn)", "kind": Card.Field.PATH, "filters": PackedStringArray(["*.tscn"])},
		{"key": "group", "label": "资产组 (可空)", "kind": Card.Field.GROUP, "placeholder": ""},
	]


func _ui_schema() -> Array:
	return [
		{"key": "id", "label": "ID", "kind": Card.Field.ID, "placeholder": "ui_id"},
		{"key": "scene_path", "label": "场景 (.tscn)", "kind": Card.Field.PATH, "filters": PackedStringArray(["*.tscn"])},
		{"key": "layer", "label": "层级", "kind": Card.Field.ENUM, "options": UIEntry.Layer},
		{"key": "cache", "label": "缓存", "kind": Card.Field.ENUM, "options": UIEntry.Cache},
	]


func _asset_schema() -> Array:
	return [
		{"key": "id", "label": "ID", "kind": Card.Field.ID, "placeholder": "asset_id"},
		{"key": "path", "label": "资源", "kind": Card.Field.PATH, "filters": PackedStringArray(["*"])},
		{"key": "group", "label": "内存组", "kind": Card.Field.GROUP, "placeholder": "core"},
	]
#endregion

#region Internal — 动作
func _reload() -> void:
	_manifest = ManifestIO.load_working_copy(_manifest_edit.text if _manifest_edit else _DEFAULT_MANIFEST)
	if _scroll_ref:
		_scroll_ref.queue_free()
	_build_sections()
	_set_status("已从磁盘载入清单", Color.GRAY)


func _on_export() -> void:
	var problems := ManifestIO.validate(_manifest)
	if problems.size() > 0:
		_set_status("导出被拦截:%s" % problems[0], Color.ORANGE_RED)
		return
	var err := ManifestIO.save_manifest(_manifest, _manifest_edit.text)
	if err != OK:
		_set_status("写清单失败 (err %d)" % err, Color.ORANGE_RED)
		return
	err = ManifestIO.generate_ids(_manifest, _ids_edit.text)
	if err != OK:
		_set_status("生成 Ids 失败 (err %d)" % err, Color.ORANGE_RED)
		return
	_save_paths_to_meta()
	EditorInterface.get_resource_filesystem().scan()
	_set_status("✔ 已导出 %d 场景 / %d UI / %d 资产 + Ids" % [
		_manifest.scenes.size(), _manifest.uis.size(), _manifest.assets.size()], Color.LIME_GREEN)


func _on_dirty() -> void:
	_set_status("● 有未导出的改动", Color.GOLD)


func _on_quick_load(section: Object) -> void:
	_open_dialog({"type": "quick_load", "section": section},
		EditorFileDialog.FILE_MODE_OPEN_FILES, PackedStringArray(["*"]))


func _on_card_browse(entry: Resource, key: String, filters: PackedStringArray) -> void:
	_open_dialog({"type": "card_path", "entry": entry, "key": key},
		EditorFileDialog.FILE_MODE_OPEN_FILE, filters)
#endregion

#region Internal — 文件框
func _build_dialog() -> void:
	_dialog = EditorFileDialog.new()
	_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_dialog.file_selected.connect(_on_file_selected)
	_dialog.files_selected.connect(_on_files_selected)
	_dialog.dir_selected.connect(_on_dir_selected)
	add_child(_dialog)


func _open_dialog(pending: Dictionary, mode: int, filters: PackedStringArray) -> void:
	_pending = pending
	_dialog.file_mode = mode
	_dialog.clear_filters()
	for f in filters:
		if f != "*":
			_dialog.add_filter(f)
	_dialog.popup_centered_ratio(0.6)


func _on_file_selected(path: String) -> void:
	match _pending.get("type"):
		"card_path":
			_pending["entry"].set(_pending["key"], path)
			_reload_from_working()
			_on_dirty()
		"manifest":
			_manifest_edit.text = path


func _on_files_selected(paths: PackedStringArray) -> void:
	if _pending.get("type") == "quick_load":
		(_pending["section"] as Object).add_from_files(paths)


func _on_dir_selected(dir: String) -> void:
	if _pending.get("type") == "ids_dir":
		_ids_edit.text = dir
#endregion

#region Internal — 杂项
## 卡片路径被外部改写后,最省事的同步方式是就地重建分区列表(条目数不多,开销可忽略)。
func _reload_from_working() -> void:
	if _scroll_ref:
		_scroll_ref.queue_free()
	_build_sections()


func _load_paths_from_meta() -> void:
	var es := EditorInterface.get_editor_settings()
	if es == null:
		return
	_manifest_edit.text = es.get_project_metadata(_META_SECTION, "manifest_path", _DEFAULT_MANIFEST)
	_ids_edit.text = es.get_project_metadata(_META_SECTION, "ids_dir", _DEFAULT_IDS_DIR)


func _save_paths_to_meta() -> void:
	var es := EditorInterface.get_editor_settings()
	if es == null:
		return
	es.set_project_metadata(_META_SECTION, "manifest_path", _manifest_edit.text)
	es.set_project_metadata(_META_SECTION, "ids_dir", _ids_edit.text)


func _set_status(text: String, color: Color) -> void:
	_status.text = "   " + text
	_status.modulate = color


func _spacer() -> Control:
	var s := Control.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return s
#endregion
