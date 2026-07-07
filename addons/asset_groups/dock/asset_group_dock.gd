@tool
extends Control

## Asset Groups 插件的 Dock 根组件:加载/持久化 [AssetManifest],把同一份实例
## 注入三个子面板(Assets/Scenes/UI),提供 Reload / Scan import / Generate All 三个顶层动作。
##
## 三个子面板互不知道彼此存在,只朝上 emit `changed`;这里收到后统一存盘 + 让
## 全部面板重刷。分组这类跨面板共享的数据靠"整体重刷"保持一致,不需要每个
## 面板互相订阅对方——这是页面级 orchestrator 收拢状态、子组件只管上抛意图的
## 前端常见分工。

const _MANIFEST_PATH := "res://src/resource/data/asset_manifest.tres"
const _DEFAULT_LIST_SPLIT_OFFSET := 236

var _manifest: AssetManifest
var _list_split_offset := _DEFAULT_LIST_SPLIT_OFFSET

@onready var _toolbar_panel: PanelContainer = %ToolbarPanel
@onready var _reload_button: Button = %ReloadButton
@onready var _generate_button: Button = %GenerateButton
@onready var _scan_import_button: Button = %ScanImportButton
@onready var _stats_label: Label = %StatsLabel
@onready var _status_label: Label = %StatusLabel
@onready var _tabs: TabContainer = %Tabs
@onready var _scene_panel: HSplitContainer = %ScenePanel
@onready var _ui_panel: HSplitContainer = %UIPanel
@onready var _asset_panel: HSplitContainer = %AssetPanel


func _ready() -> void:
	layout_direction = Control.LAYOUT_DIRECTION_LTR
	_tabs.set_tab_title(0, "Assets")
	_tabs.set_tab_title(1, "Scenes")
	_tabs.set_tab_title(2, "UI")
	_tabs.set_tab_icon(0, get_theme_icon("Folder", "EditorIcons"))
	_tabs.set_tab_icon(1, get_theme_icon("PackedScene", "EditorIcons"))
	_tabs.set_tab_icon(2, get_theme_icon("Control", "EditorIcons"))
	_setup_list_split_sync()
	_reload_button.icon = get_theme_icon("Reload", "EditorIcons")
	_generate_button.icon = get_theme_icon("Play", "EditorIcons")
	_scan_import_button.icon = get_theme_icon("Search", "EditorIcons")
	_toolbar_panel.add_theme_stylebox_override("panel", AssetGroupsStyle.toolbar_panel(self))
	_reload_button.pressed.connect(_on_reload_pressed)
	_scan_import_button.pressed.connect(_on_scan_import_pressed)
	_generate_button.pressed.connect(_on_generate_pressed)
	_scene_panel.changed.connect(_on_panel_changed)
	_ui_panel.changed.connect(_on_panel_changed)
	_asset_panel.changed.connect(_on_panel_changed)
	_load_manifest()


func _setup_list_split_sync() -> void:
	for panel in _list_split_panels():
		panel.split_offset = _list_split_offset
		panel.dragged.connect(func(offset: int) -> void: _on_list_split_dragged(panel, offset))
	_tabs.tab_changed.connect(_on_tab_changed)


func _list_split_panels() -> Array[HSplitContainer]:
	return [_asset_panel, _scene_panel, _ui_panel]


func _on_list_split_dragged(source: HSplitContainer, offset: int) -> void:
	_list_split_offset = offset
	_sync_list_split_offset(source)


func _on_tab_changed(_tab: int) -> void:
	_sync_list_split_offset(null)


func _sync_list_split_offset(except: HSplitContainer) -> void:
	for panel in _list_split_panels():
		if panel == except:
			continue
		if panel.split_offset != _list_split_offset:
			panel.split_offset = _list_split_offset


func _on_reload_pressed() -> void:
	_load_manifest()
	_status_label.text = "Reloaded from disk."


func _on_scan_import_pressed() -> void:
	var result := ManifestScanner.import_into(_manifest)
	_save_manifest()
	_refresh_all_panels()
	_update_stats()
	var added: int = int(result.added_scenes) + int(result.added_uis) + int(result.added_assets)
	if added == 0:
		_status_label.text = "Scan: nothing new (%d already registered)" % result.skipped
	else:
		_status_label.text = "Scan: +%d assets, +%d scenes, +%d ui (%d skipped)" % [
			result.added_assets, result.added_scenes, result.added_uis, result.skipped,
		]


func _on_panel_changed() -> void:
	_save_manifest()
	_refresh_all_panels()
	_update_stats()


func _load_manifest() -> void:
	if ResourceLoader.exists(_MANIFEST_PATH):
		_manifest = ResourceLoader.load(_MANIFEST_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as AssetManifest
	else:
		_manifest = AssetManifest.new()
		_save_manifest()
	_refresh_all_panels()
	_update_stats()


func _save_manifest() -> void:
	var err := ResourceSaver.save(_manifest, _MANIFEST_PATH)
	if err != OK:
		_status_label.text = "Failed to save manifest (error %d)" % err


func _refresh_all_panels() -> void:
	_scene_panel.set_manifest(_manifest)
	_ui_panel.set_manifest(_manifest)
	_asset_panel.set_manifest(_manifest)


func _update_stats() -> void:
	_stats_label.text = "%d assets · %d scenes · %d ui · %d groups" % [
		_manifest.assets.size(), _manifest.scenes.size(), _manifest.uis.size(), _manifest.groups.size(),
	]


func _on_generate_pressed() -> void:
	var hard_errors := ManifestValidator.hard_errors(_manifest)
	if not hard_errors.is_empty():
		_status_label.text = "Blocked: " + ", ".join(hard_errors)
		return

	var errors := PackedStringArray()
	errors.append_array(RegistryGenerator.generate_and_save(_manifest))
	errors.append_array(AccessorsGenerator.generate_and_save(_manifest))
	EditorInterface.get_resource_filesystem().scan()

	if not errors.is_empty():
		_status_label.text = "Generate failed: " + ", ".join(errors)
		return

	var warnings := ManifestValidator.soft_warnings(_manifest)
	if warnings.is_empty():
		_status_label.text = "Generated at %s" % Time.get_time_string_from_system()
	else:
		_status_label.text = "Generated with warnings: " + ", ".join(warnings)
