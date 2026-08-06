@tool
class_name AssetGroupsEditorTheme
extends RefCounted

## 只能从编辑器主题取的图标与 StyleBox,集中在此应用;tscn 负责静态文案与布局。


static func apply_dock(
	host: Control,
	toolbar_panel: PanelContainer,
	tabs: TabContainer,
	reload_button: Button,
	generate_button: Button,
	scan_import_button: Button,
	status_label: Label
) -> void:
	toolbar_panel.add_theme_stylebox_override("panel", AssetGroupsStyle.toolbar_panel(host))
	reload_button.icon = host.get_theme_icon("Reload", "EditorIcons")
	generate_button.icon = host.get_theme_icon("Play", "EditorIcons")
	scan_import_button.icon = host.get_theme_icon("Search", "EditorIcons")
	apply_status_label(host, status_label, "font_color")
	tabs.set_tab_icon(0, host.get_theme_icon("Folder", "EditorIcons"))
	tabs.set_tab_icon(1, host.get_theme_icon("File", "EditorIcons"))
	tabs.set_tab_icon(2, host.get_theme_icon("PackedScene", "EditorIcons"))
	tabs.set_tab_icon(3, host.get_theme_icon("Control", "EditorIcons"))


static func apply_status_label(host: Control, status_label: Label, color_name: String) -> void:
	status_label.add_theme_color_override("font_color", host.get_theme_color(color_name, "Editor"))


static func apply_list_panel(
	host: Control,
	detail_panel: PanelContainer,
	id_list: ItemList,
	add_button: Button,
	remove_button: Button,
	browse_button: Button,
	quick_open_button: Button = null
) -> void:
	add_button.icon = host.get_theme_icon("Add", "EditorIcons")
	remove_button.icon = host.get_theme_icon("Remove", "EditorIcons")
	browse_button.icon = host.get_theme_icon("Folder", "EditorIcons")
	if quick_open_button != null:
		quick_open_button.icon = host.get_theme_icon("Search", "EditorIcons")
	detail_panel.add_theme_stylebox_override("panel", AssetGroupsStyle.card_panel(host))
	var selected_style := AssetGroupsStyle.selected_row(host)
	id_list.add_theme_stylebox_override("selected", selected_style)
	id_list.add_theme_stylebox_override("selected_focus", selected_style)
	_apply_outline_danger_button(host, remove_button)


static func apply_asset_toolbar(host: Control, add_id_button: Button, add_group_button: Button) -> void:
	add_id_button.icon = host.get_theme_icon("Add", "EditorIcons")
	add_group_button.icon = host.get_theme_icon("Folder", "EditorIcons")


static func apply_asset_detail(
	host: Control,
	detail_panel: PanelContainer,
	drag_hint_panel: PanelContainer,
	remove_button: Button,
	multi_remove_button: Button,
	browse_button: Button
) -> void:
	detail_panel.add_theme_stylebox_override("panel", AssetGroupsStyle.card_panel(host))
	drag_hint_panel.add_theme_stylebox_override("panel", AssetGroupsStyle.hint_panel(host))
	_apply_outline_danger_button(host, remove_button)
	_apply_outline_danger_button(host, multi_remove_button)
	remove_button.icon = host.get_theme_icon("Remove", "EditorIcons")
	multi_remove_button.icon = host.get_theme_icon("Remove", "EditorIcons")
	browse_button.icon = host.get_theme_icon("Folder", "EditorIcons")


static func apply_tree(host: Control, tree: Tree) -> void:
	var selected_style := AssetGroupsStyle.selected_row(host)
	tree.add_theme_stylebox_override("selected", selected_style)
	tree.add_theme_stylebox_override("selected_focus", selected_style)


static func configure_dynamic_group_name_edit(edit: LineEdit) -> void:
	edit.placeholder_text = "例如 boss_fight"
	edit.clear_button_enabled = true
	edit.layout_direction = Control.LAYOUT_DIRECTION_LTR
	edit.text_direction = Control.TEXT_DIRECTION_LTR
	edit.alignment = HORIZONTAL_ALIGNMENT_LEFT
	edit.language = "en"


static func apply_danger_button(host: Control, button: Button) -> void:
	_apply_outline_danger_button(host, button)


static func _apply_outline_danger_button(host: Control, button: Button) -> void:
	button.add_theme_stylebox_override("normal", AssetGroupsStyle.outline_button(host, "error_color"))
	button.add_theme_color_override("font_color", host.get_theme_color("error_color", "Editor"))
