@tool
class_name AssetGroupsStyle
extends RefCounted

## 共用的 [StyleBoxFlat] 生成器,给 Dock 的各个组件做视觉分区/高亮用。
##
## 故意不写死颜色——全部从 [param host] 当前的编辑器主题([code]"Editor"[/code]
## 主题类型)取色,深色/浅色编辑器主题下都不会违和。哪个面板需要"块状分区"就调
## 对应函数拿一个 [StyleBoxFlat],不在每个面板脚本里重复 new 一遍。

#region Public API
## 工具栏背景:比内容区更深一级的底色,用来把"操作区"和"内容区"分开。
static func toolbar_panel(host: Control) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = host.get_theme_color("dark_color_1", "Editor")
	style.set_content_margin_all(6)
	style.set_corner_radius_all(4)
	return style


## 详情表单的"浮卡"背景:比内容区略亮 + 投影,让它从列表里"浮"出来。
static func card_panel(host: Control) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = host.get_theme_color("base_color", "Editor").lightened(0.08)
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	style.set_corner_radius_all(6)
	style.shadow_size = 4
	style.shadow_color = host.get_theme_color("dark_color_2", "Editor")
	return style


## 提示框背景:柔和色块,用于"这里是个放置/操作目标区"这类提示文案。
static func hint_panel(host: Control) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var accent := host.get_theme_color("accent_color", "Editor")
	style.bg_color = Color(accent.r, accent.g, accent.b, 0.08)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(accent.r, accent.g, accent.b, 0.35)
	style.set_content_margin_all(8)
	style.set_corner_radius_all(4)
	return style


## 列表选中行:编辑器同款半透明蒙层 + 左侧强调色竖条,ItemList/Tree 通用
## ([code]"selected"[/code]/[code]"selected_focus"[/code] 两个 override 槽位都传它)。
static func selected_row(host: Control) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = host.get_theme_color("box_selection_fill_color", "Editor")
	style.border_width_left = 4
	style.border_color = host.get_theme_color("accent_color", "Editor")
	style.content_margin_left = 6
	return style


## 危险操作按钮的镂空描边样式(如 Remove):透明底 + 描边,避免实心红块太抢眼。
static func outline_button(host: Control, tint_color_name: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var tint := host.get_theme_color(tint_color_name, "Editor")
	style.bg_color = Color(0, 0, 0, 0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = tint
	style.set_content_margin_all(4)
	style.set_corner_radius_all(4)
	return style


## 详情表单里的 id 输入框:标签英文、占位中文,带清除按钮;强制 LTR 光标。
static func configure_id_edit(edit: LineEdit) -> void:
	_apply_ltr_edit(edit)
	edit.placeholder_text = "例如 main_menu（留空则取文件名）"
	edit.clear_button_enabled = true
	edit.language = "en"


## 资源路径输入框:占位中文说明选取方式,内容仍为 res:// 路径。
static func configure_path_edit(edit: LineEdit) -> void:
	_apply_ltr_edit(edit)
	edit.placeholder_text = "浏览、拖拽或快速打开选择，也可粘贴 res:// 路径"
	edit.clear_button_enabled = true
	edit.language = "en"


## 新建/重命名分组弹窗里的输入框。
static func configure_group_name_edit(edit: LineEdit) -> void:
	_apply_ltr_edit(edit)
	edit.placeholder_text = "例如 boss_fight"
	edit.clear_button_enabled = true
	edit.language = "en"
#endregion

#region Helpers
static func _apply_ltr_edit(edit: LineEdit) -> void:
	edit.layout_direction = Control.LAYOUT_DIRECTION_LTR
	edit.text_direction = Control.TEXT_DIRECTION_LTR
	edit.alignment = HORIZONTAL_ALIGNMENT_LEFT
	edit.structured_text_bidi_override = TextServer.STRUCTURED_TEXT_DEFAULT
#endregion
