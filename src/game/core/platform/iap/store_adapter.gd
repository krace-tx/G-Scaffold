class_name StoreAdapter
extends RefCounted

## godot-iap 原生商店与支付适配器。
## 封装与应用商店 (Google Play / App Store) 的连接握手、商品详情查询与交易结算完成。

const Types := preload("res://addons/godot-iap/types.gd")

signal connected
signal products_fetched(price_map: Dictionary)
signal purchase_finished(result: Result)

var _wrapper: GodotIapWrapper = null


func initialize() -> Result:
	_wrapper = GodotIapWrapper.new()
	NodeUtils.mount_required(_wrapper, Platform, "IapWrapper")
	_wrapper.purchase_updated.connect(_on_purchase_updated)
	_wrapper.purchase_error.connect(_on_purchase_error)
	_wrapper.connected.connect(_on_connected)

	if _wrapper._native_plugin != null:
		_wrapper.init_connection()
	else:
		App.log.warn("StoreAdapter", "Native plugin not available, skip store connection")
	return Result.ok()


func fetch_products(skus: Array[String]) -> void:
	if skus.is_empty():
		App.log.info("StoreAdapter", "SKUS list is empty, skip fetching.")
		return

	App.log.info("StoreAdapter", "Fetching products: %s" % str(skus))
	var request := Types.ProductRequest.new()
	request.skus = skus
	request.type = Types.ProductQueryType.IN_APP

	var products: Array = await _wrapper.fetch_products(request)
	var price_map := {}
	for product in products:
		price_map[String(product.id)] = "%s %s" % [product.currency, product.price]

	products_fetched.emit(price_map)


func request_purchase(sku: String) -> void:
	var props := Types.RequestPurchaseProps.new()
	props.type = Types.ProductQueryType.IN_APP
	props.request = Types.RequestPurchasePropsByPlatforms.new()
	props.request.google = Types.RequestPurchaseAndroidProps.new()
	props.request.google.skus = [sku] as Array[String]
	props.request.apple = Types.RequestPurchaseIosProps.new()
	props.request.apple.sku = sku
	_wrapper.request_purchase(props)


func _on_connected() -> void:
	connected.emit()
	fetch_products(PlatformCatalog.SKUS)


func _on_purchase_updated(purchase: Dictionary) -> void:
	var product_id := str(purchase.get("productId", ""))
	var transaction_id := str(purchase.get("transactionId", ""))
	var result = _wrapper.finish_transaction_dict(purchase, true)
	if result.success:
		purchase_finished.emit(Result.ok({ "sku": product_id, "transaction_id": transaction_id }))
	else:
		purchase_finished.emit(Result.err("finish transaction failed"))


func _on_purchase_error(err: Dictionary) -> void:
	App.log.info("StoreAdapter", "Purchase error: %s %s" % [err.get("code"), err.get("message")])
	purchase_finished.emit(Result.err(str(err.get("message", "purchase failed"))))
