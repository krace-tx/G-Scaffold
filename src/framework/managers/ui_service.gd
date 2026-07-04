class_name UIService
extends Node

## 分层 UI 生命周期服务:按层级管理界面的打开 / 关闭 / 返回键路由 / 缓存复用。
##
## 全项目打开界面一律走 [method open],不要各自 instantiate + add_child——那样
## 层级、栈、返回键、缓存全失控。不管理顶层场景(那是 SceneService),不管理
## 界面内部业务逻辑。完整规格见 docs/modules/ui-service.md。
##
## 由 Bootstrap 创建并挂在 [App] 下,持有六个 CanvasLayer(每层一个),这样界面
## 才能在场景切换后依然常驻。

#region Constants & Enums
## 各逻辑层 → CanvasLayer.layer 实际数值。**刻意与 SceneService 转场遮罩的
## layer=100 错开**:HUD~Loading 全在 100 以下(转场时被黑幕盖住),Debug 在
## 100 以上(转场时仍可见,方便调试)。
const _LAYER_ORDER: Dictionary = {
	UIRegistryEntry.Layer.HUD: 10,
	UIRegistryEntry.Layer.WINDOW: 20,
	UIRegistryEntry.Layer.POPUP: 30,
	UIRegistryEntry.Layer.TOAST: 40,
	UIRegistryEntry.Layer.LOADING: 50,
	UIRegistryEntry.Layer.DEBUG: 110,
}

## 返回键的响应层级顺序:只有 Popup / Window 这类模态界面吃返回键,
## HUD / Toast / Loading / Debug 不响应。按此顺序取最上层的一个处理。
const _BACK_LAYERS: Array[UIRegistryEntry.Layer] = [
	UIRegistryEntry.Layer.POPUP,
	UIRegistryEntry.Layer.WINDOW,
]
#endregion

#region Exports & State
## id → 界面记录的注册表,_ready 时一次性加载。
var _registry: UIRegistry

## 逻辑层 → 该层的 CanvasLayer 节点。界面 add 到对应层的 CanvasLayer 下。
var _layers: Dictionary = {}

## 逻辑层 → 该层当前打开的界面栈(后进的在栈顶,返回键先处理栈顶)。
var _stacks: Dictionary = {}

## 当前打开中的界面:id → 实例。用于防重复打开与按 id 关闭。
var _open: Dictionary = {}

## KEEP 策略的界面关闭后暂存于此:id → 已脱离层树的实例,下次打开直接复用。
var _cache: Dictionary = {}
#endregion

#region Lifecycle
func _ready() -> void:
	_registry = load(ResPaths.UI_REGISTRY) as UIRegistry
	_build_layers()
#endregion

#region Public API
## 打开 [param ui_id] 对应的界面并返回其实例;id 未注册或加载失败时返回 null。
## 已打开的界面重复调用直接返回现有实例,不重复实例化。[param params] 透传给
## 界面的 [method BaseUI._on_open]。
func open(ui_id: StringName, params: Dictionary = {}) -> BaseUI:
	if _open.has(ui_id):
		return _open[ui_id]

	var entry := _registry.find(ui_id) if _registry else null
	if entry == null:
		App.log.error("ui", "unknown ui id: %s" % ui_id)
		return null

	var ui := _acquire(entry)
	if ui == null:
		App.log.error("ui", "failed to load ui: %s" % entry.scene_path)
		return null

	# 挂到对应层,并以 ui_id 命名(调试树可读、也便于按名查找)。
	NodeUtils.mount_required(ui, _layers[entry.layer], String(ui_id))
	(_stacks[entry.layer] as Array).append(ui)
	_open[ui_id] = ui
	ui._on_open(params)
	Bus.ui_opened.emit(ui_id)
	return ui


## 关闭 [param ui_id];未打开时静默返回。按注册表的缓存策略决定实例是留存复用
## (KEEP)还是销毁(DESTROY)。
func close(ui_id: StringName) -> void:
	if not _open.has(ui_id):
		return
	var ui: BaseUI = _open[ui_id]
	var entry := _registry.find(ui_id)

	ui._on_close()
	(_stacks[entry.layer] as Array).erase(ui)
	_open.erase(ui_id)
	_layers[entry.layer].remove_child(ui)

	if entry.cache == UIRegistryEntry.Cache.KEEP:
		_cache[ui_id] = ui
	else:
		ui.queue_free()
	Bus.ui_closed.emit(ui_id)


## 处理返回键(由 App 在收到 Android GO_BACK / ui_cancel 时调用)。按层级从上到下
## 找到最上层的模态界面:先给它 [method BaseUI._on_back] 自决;未消费则默认关闭它。
## 返回 true = 已被某个界面处理;false = 当前没有可响应的界面(交由上层做场景级返回)。
func handle_back() -> bool:
	for layer: UIRegistryEntry.Layer in _BACK_LAYERS:
		var stack: Array = _stacks[layer]
		if stack.is_empty():
			continue
		var top: BaseUI = stack.back()
		if not top._on_back():
			close(top.get_meta(&"ui_id"))
		return true
	return false


## 界面当前是否打开中。
func is_open(ui_id: StringName) -> bool:
	return _open.has(ui_id)
#endregion

#region Internal
## 取得界面实例:优先复用 KEEP 缓存里的,否则加载场景实例化一份。
func _acquire(entry: UIRegistryEntry) -> BaseUI:
	if _cache.has(entry.id):
		return _pop_cache(entry.id)
	var packed := load(entry.scene_path) as PackedScene
	if packed == null:
		return null
	var ui := packed.instantiate() as BaseUI
	if ui != null:
		ui.set_meta(&"ui_id", entry.id)
	return ui


func _pop_cache(ui_id: StringName) -> BaseUI:
	var ui: BaseUI = _cache[ui_id]
	_cache.erase(ui_id)
	return ui


## 为每个逻辑层建一个 CanvasLayer 并初始化空栈。
func _build_layers() -> void:
	for layer: UIRegistryEntry.Layer in _LAYER_ORDER:
		var canvas := CanvasLayer.new()
		canvas.layer = _LAYER_ORDER[layer]
		# 按枚举名命名(UILayer_POPUP 等),调试场景树一眼可读。
		NodeUtils.mount_required(canvas, self, "UILayer_%s" % UIRegistryEntry.Layer.keys()[layer])
		_layers[layer] = canvas
		_stacks[layer] = []
#endregion
