class_name MainMenu
extends BaseScene

## Demo 主菜单:全流程演示的中枢——进关卡、开设置弹窗、看激励广告发奖并存档、
## 开调试面板。金币数从存档读出并显示,用来演示"看广告发奖 → 存档 → 重启仍在"。
##
## 占位性质,UI 用代码构建(demo 面板不值得单独维护 .tscn)。真实游戏在此替换为
## 美术菜单,但调用 App.xxx / Bus 的模式照搬。

#region Constants & Enums
const _AD_REWARD: int = 10          ## 每次看完广告发放的金币
const _SAVE_KEY_COINS: String = "coins"
#endregion

#region Exports & State
var _coins_label: Label
#endregion

#region Public API
func _on_enter(_params: Dictionary) -> void:
	App.log.info("main_menu", "entered")
	_build_ui()
	_refresh_coins()
#endregion

#region Internal
func _build_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	NodeUtils.mount_required(vbox, self, "VBox")

	var title := Label.new()
	title.text = "G-Scaffold Demo — Main Menu"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	NodeUtils.mount_required(title, vbox, "Title")

	_coins_label = Label.new()
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	NodeUtils.mount_required(_coins_label, vbox, "CoinsLabel")

	_add_button(vbox, "EnterLevelButton", "Enter Level", func() -> void: App.scenes.replace(Scenes.LEVEL))
	_add_button(vbox, "SettingsButton", "Settings", func() -> void: App.ui.open(Uis.SETTINGS_PANEL))
	_add_button(vbox, "DebugPanelButton", "Debug Panel", func() -> void: App.ui.open(Uis.DEBUG_PANEL))


func _add_button(parent: Node, node_name: String, text: String, on_press: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(220, 0)
	b.pressed.connect(on_press)
	NodeUtils.mount_required(b, parent, node_name)


func _refresh_coins() -> void:
	if _coins_label != null:
		_coins_label.text = "Coins: %d" % int(App.save.get_value(_SAVE_KEY_COINS, 0))
#endregion
