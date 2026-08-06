@tool
extends Control

## Asset Groups 插件的 Dock 根组件:加载/持久化 [EditAssetManifest],把同一份实例
## 注入三个子面板(Assets/Scenes/UI),提供 Reload / Scan import / Generate All 三个顶层动作。
##
## 三个子面板互不知道彼此存在,只朝上 emit `changed`;这里收到后统一存盘 + 让
## 全部面板重刷。分组这类跨面板共享的数据靠"整体重刷"保持一致,不需要每个
## 面板互相订阅对方——这是页面级 orchestrator 收拢状态、子组件只管上抛意图的
## 前端常见分工。

#region Constants & State
enum StatusKind { NORMAL, BUSY, SUCCESS, WARNING, ERROR }

## 唯一真源清单的存放路径。
const _MANIFEST_PATH := "res://src/resource/data/asset_manifest.tres"
## 插件内私有 Result,用于可失败的 manifest 读写。
const _Result := preload("res://addons/asset_groups/internal/asset_group_result.gd")
## 各子页面 HSplitContainer 的默认分割位置（保证切换分页时布局一致性）。
const _DEFAULT_LIST_SPLIT_OFFSET := 236

## 当前加载的编辑态数据模型实例。
var _manifest: EditAssetManifest
## 当前同步的分割位置。
var _list_split_offset := _DEFAULT_LIST_SPLIT_OFFSET
## 编辑器接口,用于底部状态栏 toast。
var _editor_interface: EditorInterface
## 上次成功 Generate 时的 manifest 分段指纹,用于脏标记式增量写入。
var _codegen_signatures: Dictionary = {}

# --- UI 节点引用 ---
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
@onready var _resource_panel: HSplitContainer = %ResourcePanel
#endregion

#region Lifecycle
func setup_editor_interface(editor_interface: EditorInterface) -> void:
	_editor_interface = editor_interface


func _ready() -> void:
	AssetGroupsEditorTheme.apply_dock(
		self, _toolbar_panel, _tabs, _reload_button, _generate_button, _scan_import_button, _status_label
	)
	_setup_list_split_sync()
	_reload_button.pressed.connect(_on_reload_pressed)
	_scan_import_button.pressed.connect(_on_scan_import_pressed)
	_generate_button.pressed.connect(_on_generate_pressed)
	
	# 极简接收子面板的变更通知
	_scene_panel.changed.connect(_on_panel_changed)
	_ui_panel.changed.connect(_on_panel_changed)
	_asset_panel.changed.connect(_on_panel_changed)
	_resource_panel.changed.connect(_on_panel_changed)
	_asset_panel.status_message.connect(_on_asset_status_message)
	_resource_panel.status_message.connect(_on_asset_status_message)
	
	_load_manifest()
	_set_status("Ready", PackedStringArray(), StatusKind.NORMAL)
#endregion

#region List Layout Sync
## 建立 UI 分割线的联动机制，确保在不同 Tab 之间切换时，分割线位置保持一致。
func _setup_list_split_sync() -> void:
	for panel in _list_split_panels():
		panel.split_offset = _list_split_offset
		panel.dragged.connect(func(offset: int) -> void: _on_list_split_dragged(panel, offset))
	_tabs.tab_changed.connect(_on_tab_changed)

func _list_split_panels() -> Array[HSplitContainer]:
	return [_asset_panel, _resource_panel, _scene_panel, _ui_panel]

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
#endregion

#region Actions & IO
## 重载按钮回调：从磁盘强制刷新 manifest，丢弃未保存编辑并重建各 Tab UI。
func _on_reload_pressed() -> void:
	_begin_action("Reloading manifest...")
	await _load_manifest(true)
	_end_action()
	_set_status("Reloaded from disk.", PackedStringArray(), StatusKind.SUCCESS)


## 扫描导入回调：触发 [ManifestScanner] 扫描文件系统，追加资源到 manifest。
func _on_scan_import_pressed() -> void:
	_begin_action("Scanning src/game and src/assets...")
	var result := ManifestScanner.import_into(_manifest)
	_save_manifest()
	_refresh_all_panels()
	_update_stats()
	_end_action()
	var added: int = int(result.added_scenes) + int(result.added_uis) + int(result.added_assets) + int(result.added_resources)
	if added == 0:
		_set_status(
			"Scan: nothing new (%d already registered)" % result.skipped,
			PackedStringArray(),
			StatusKind.NORMAL
		)
	else:
		_set_status(
			"Scan: +%d assets, +%d scenes, +%d ui, +%d resources (%d skipped)" % [
				result.added_assets, result.added_scenes, result.added_uis, result.added_resources, result.skipped,
			],
			PackedStringArray(),
			StatusKind.SUCCESS
		)

## 当子面板发生变更时：统一存盘、刷新所有 UI 并更新统计信息。
func _on_panel_changed() -> void:
	_save_manifest()
	_refresh_all_panels()
	_update_stats()

## 加载 manifest。若文件不存在则初始化一个空实例并落盘。
## [param from_disk_reload]: true 时释放旧引用、重读 tres 并硬重置三个子面板 UI。
func _load_manifest(from_disk_reload: bool = false) -> void:
	_codegen_signatures.clear()
	if from_disk_reload:
		await _prepare_manifest_reload_from_disk()

	if ResourceLoader.exists(_MANIFEST_PATH):
		var cache_mode := (
			ResourceLoader.CACHE_MODE_REPLACE_DEEP
			if from_disk_reload
			else ResourceLoader.CACHE_MODE_IGNORE
		)
		_manifest = ResourceLoader.load(_MANIFEST_PATH, "", cache_mode) as EditAssetManifest
		if _manifest == null:
			_set_status("Failed to load manifest.", PackedStringArray(), StatusKind.ERROR)
			_manifest = EditAssetManifest.new()
	else:
		_manifest = EditAssetManifest.new()
		_save_manifest()

	if from_disk_reload:
		_reload_all_panels()
	else:
		_refresh_all_panels()
	_update_stats()


func _prepare_manifest_reload_from_disk() -> void:
	_manifest = null
	if _editor_interface == null:
		return
	var fs := _editor_interface.get_resource_filesystem()
	if fs != null:
		fs.update_file(_MANIFEST_PATH)
		await _wait_for_filesystem(fs)


func _wait_for_filesystem(fs: EditorFileSystem) -> void:
	await get_tree().process_frame
	while fs.is_scanning():
		await get_tree().process_frame

## 尝试保存 manifest。若失败则将错误信息反馈至状态栏。
func _save_manifest() -> void:
	var result: RefCounted = _save_manifest_result()
	if result == null:
		_set_status("Failed to save manifest (internal error).", PackedStringArray(), StatusKind.ERROR)
		return
	if result.is_err():
		_set_status(String(result.error), PackedStringArray(), StatusKind.ERROR)
		return
	if _editor_interface != null:
		var fs := _editor_interface.get_resource_filesystem()
		if fs != null:
			fs.update_file(_MANIFEST_PATH)


func _on_asset_status_message(text: String) -> void:
	_set_status(text, PackedStringArray(), StatusKind.ERROR)

func _save_manifest_result() -> RefCounted:
	var dir_err := AssetGroupsGeneratorUtils.ensure_parent_dir(_MANIFEST_PATH)
	if dir_err != "":
		return _Result.err(dir_err)
	var err := ResourceSaver.save(_manifest, _MANIFEST_PATH)
	if err != OK:
		return _Result.err("Failed to save manifest (error %d)" % err)
	return _Result.ok(null)

func _refresh_all_panels() -> void:
	_scene_panel.set_manifest(_manifest)
	_ui_panel.set_manifest(_manifest)
	_asset_panel.set_manifest(_manifest)
	_resource_panel.set_manifest(_manifest)


func _reload_all_panels() -> void:
	_scene_panel.reload_manifest(_manifest)
	_ui_panel.reload_manifest(_manifest)
	_asset_panel.reload_manifest(_manifest)
	_resource_panel.reload_manifest(_manifest)

func _update_stats() -> void:
	_stats_label.text = "%d assets · %d scenes · %d ui · %d resources · %d groups" % [
		_manifest.assets.size(), _manifest.scenes.size(), _manifest.uis.size(), _manifest.resources.size(), _manifest.groups.size() + _manifest.resource_groups.size(),
	]
#endregion

#region Generation Pipeline
## 执行全量生成管线：校验 -> 写入注册表 -> 生成查表类 -> 增量刷新文件系统。
func _on_generate_pressed() -> void:
	_begin_action("Generating registry & accessors...")
	await _generate_all()
	_end_action()


func _generate_all() -> void:
	AssetGroupsGeneratorUtils.begin_resolve_batch()

	# 1. 硬校验：若存在未完成或冲突的条目，阻断执行
	_set_status("Validating manifest...", PackedStringArray(), StatusKind.BUSY)
	await get_tree().process_frame
	var hard_errors := ManifestValidator.hard_errors(_manifest)
	if not hard_errors.is_empty():
		_set_status("Blocked: " + ", ".join(hard_errors), hard_errors, StatusKind.ERROR)
		return

	var current_signatures := ManifestCodegenFingerprints.compute(_manifest)
	var flags := ManifestCodegenFingerprints.derive_flags(current_signatures, _codegen_signatures)
	if not flags.any_output():
		_set_status("Already up to date (no changes since last generate).", PackedStringArray(), StatusKind.NORMAL)
		return

	var errors := PackedStringArray()
	var written_paths := PackedStringArray()
	var skipped := flags.skipped_labels()

	# 2. 注册表：只写脏分段
	if flags.any_registry():
		_set_status("Generating registries (1/2)...", PackedStringArray(), StatusKind.BUSY)
		var reg_result := RegistryGenerator.generate_and_save(_manifest, flags)
		errors.append_array(reg_result["errors"])
		written_paths.append_array(reg_result["written_paths"])
		await get_tree().process_frame

	# 3. 查表类：只写脏分段,跳过大文件可避免编辑器重解析
	if flags.any_accessor():
		_set_status("Generating accessors (2/2)...", PackedStringArray(), StatusKind.BUSY)
		var acc_result := AccessorsGenerator.generate_and_save(_manifest, flags)
		errors.append_array(acc_result["errors"])
		written_paths.append_array(acc_result["written_paths"])
		await get_tree().process_frame

	AssetGroupsGeneratorUtils.refresh_generated_files(written_paths)

	if not errors.is_empty():
		_set_status("Generate failed: " + ", ".join(errors), errors, StatusKind.ERROR)
		return

	_codegen_signatures = current_signatures

	# 4. 软警告 + 跳过提示
	var warnings := ManifestValidator.soft_warnings(_manifest)
	if not skipped.is_empty():
		warnings.append("Skipped unchanged: " + ", ".join(skipped))

	if warnings.is_empty():
		_set_status("Generated at %s" % Time.get_time_string_from_system(), PackedStringArray(), StatusKind.SUCCESS)
	else:
		_set_status(
			"Generated with %d notices (see Output)" % warnings.size(),
			warnings,
			StatusKind.WARNING
		)


func _begin_action(message: String) -> void:
	_set_toolbar_busy(true)
	_set_status(message, PackedStringArray(), StatusKind.BUSY)


func _end_action() -> void:
	_set_toolbar_busy(false)


func _set_toolbar_busy(busy: bool) -> void:
	_reload_button.disabled = busy
	_scan_import_button.disabled = busy
	_generate_button.disabled = busy


func _set_status(
	message: String,
	details: PackedStringArray = PackedStringArray(),
	kind: StatusKind = StatusKind.NORMAL
) -> void:
	if is_node_ready():
		_status_label.text = message
		_status_label.tooltip_text = message if message.length() > 48 else ""
		_apply_status_style(kind)
	_log_status(message, details)
	_toast_status(message, kind)


func _apply_status_style(kind: StatusKind) -> void:
	var color_name := "font_color"
	match kind:
		StatusKind.BUSY:
			color_name = "accent_color"
		StatusKind.SUCCESS:
			color_name = "success_color"
		StatusKind.WARNING:
			color_name = "warning_color"
		StatusKind.ERROR:
			color_name = "error_color"
	AssetGroupsEditorTheme.apply_status_label(self, _status_label, color_name)


func _toast_status(message: String, kind: StatusKind) -> void:
	if _editor_interface == null or kind == StatusKind.BUSY:
		return
	var toaster := _editor_interface.get_editor_toaster()
	if toaster == null:
		return
	var prefix := "[Asset Groups] "
	var severity := EditorToaster.SEVERITY_INFO
	match kind:
		StatusKind.ERROR:
			prefix += "Error: "
			severity = EditorToaster.SEVERITY_ERROR
		StatusKind.WARNING:
			prefix += "Warning: "
			severity = EditorToaster.SEVERITY_WARNING
	toaster.push_toast(prefix + message, severity)


func _log_status(message: String, details: PackedStringArray = PackedStringArray()) -> void:
	print("[Asset Groups] %s" % message)
	for line in details:
		print("[Asset Groups]   • %s" % line)
#endregion
