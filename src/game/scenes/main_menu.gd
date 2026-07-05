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
	_add_button(vbox, "SettingsButton", "Settings", func() -> void: App.ui.open(Uis.SETTINGS))
	_add_button(vbox, "WatchAdButton", "Watch Ad (+%d coins)" % _AD_REWARD, _on_watch_ad)
	_add_button(vbox, "DebugPanelButton", "Debug Panel", func() -> void: App.ui.open(Uis.DEBUG))


func _add_button(parent: Node, node_name: String, text: String, on_press: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(220, 0)
	b.pressed.connect(on_press)
	NodeUtils.mount_required(b, parent, node_name)


## 看激励广告 → 发奖流程:请求 → (Null 模拟观看) → 看完则加金币、存档、发 Bus 事实。
func _on_watch_ad() -> void:
	# @abstract show_rewarded 编译期看不出是协程,但 Null/真实现里都有 await,必须等。
	@warning_ignore("redundant_await")
	var res := await App.platform.ads.show_rewarded(&"double_coins")
	if not res.is_rewarded():
		App.log.info("main_menu", "ad not rewarded (%s)" % res.status)
		return
	var coins: int = int(App.save.get_value(_SAVE_KEY_COINS, 0)) + _AD_REWARD
	App.save.set_value(_SAVE_KEY_COINS, coins)
	App.save.flush()                       # 立即落盘,重启后金币仍在
	Bus.ad_reward_granted.emit(&"double_coins")   # 事实:奖励已发放
	_refresh_coins()


func _refresh_coins() -> void:
	if _coins_label != null:
		_coins_label.text = "Coins: %d" % int(App.save.get_value(_SAVE_KEY_COINS, 0))
#endregion
