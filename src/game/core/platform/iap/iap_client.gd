class_name IapClient
extends RefCounted

## 内购结算子系统统一入口门面 (Platform.iap)。
## 负责商品价格本地缓存加载、发起商店购买与恢复购买。

signal products_updated

var _adapter = null
var _price_cache: SkuPrice = SkuPrice.new()


#region Lifecycle
func initialize() -> Result:
	await _load_prices()

	if App.env.is_mobile():
		var store := StoreAdapter.new()
		_adapter = store
		store.products_fetched.connect(_on_products_fetched)
	else:
		var mock := MockStoreAdapter.new()
		_adapter = mock

	return _adapter.initialize()
#endregion


#region Public API
## 查询指定商品 SKU 的本地化展示价格；无缓存时返回空字符串。
func get_price(sku: String) -> String:
	return str(_price_cache.prices.get(sku, ""))


## 发起商品购买。
## 购买并完成确认返回 [method Result.ok]（带商品信息与订单号），失败/取消返回 [method Result.err]。
func purchase(sku: String) -> Result:
	if sku.is_empty():
		return Result.err("empty_sku")
	if _adapter == null:
		return Result.err("iap_not_initialized")

	App.log.info("IapClient", "Requesting purchase for SKU: %s" % sku)
	_adapter.request_purchase(sku)
	return await _adapter.purchase_finished


## 恢复已购买的非消耗型商品。
func restore_purchases() -> Result:
	if not App.env.is_mobile():
		App.log.info("IapClient", "Mock restore purchases succeeded.")
		return Result.ok()
	# TODO: 接入对应平台的原生恢复购买接口
	App.log.warn("IapClient", "restore_purchases not implemented on current native SDK yet")
	return Result.err("not_implemented")
#endregion


#region Internal
func _on_products_fetched(price_map: Dictionary) -> void:
	if price_map.is_empty():
		return
	for product_id in price_map:
		_price_cache.prices[String(product_id)] = price_map[product_id]
	_save_prices()
	products_updated.emit()


func _load_prices() -> void:
	if App.persist == null:
		return
	var item := SkuPrice.storage_item()
	App.persist.bind(item)
	var res: Result = await App.persist.read_async(item, ReadMode.LOCAL_ONLY)
	if res.is_ok() and res.value is Dictionary:
		_price_cache = SkuPrice.decode(res.value as Dictionary)


func _save_prices() -> void:
	if App.persist == null:
		return
	var item := SkuPrice.storage_item()
	App.persist.bind(item)
	await App.persist.write_async(item, _price_cache.encode(), WriteMode.LOCAL_ONLY)
#endregion
