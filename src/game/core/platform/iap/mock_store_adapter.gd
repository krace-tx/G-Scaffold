class_name MockStoreAdapter
extends RefCounted

## Mock 商店与支付适配器。
## 在 PC / 编辑器环境下模拟商品价格返回、购买成功与恢复购买。

@warning_ignore("unused_signal")
signal connected
@warning_ignore("unused_signal")
signal products_fetched(price_map: Dictionary)
signal purchase_finished(result: Result)


func initialize() -> Result:
	App.log.info("MockStoreAdapter", "Mock IAP store adapter initialized")
	return Result.ok()


func fetch_products(_skus: Array[String]) -> void:
	App.log.debug("MockStoreAdapter", "Mock fetch products called")


func request_purchase(sku: String) -> void:
	App.log.info("MockStoreAdapter", "Mock purchase succeeded for SKU: %s" % sku)
	purchase_finished.emit(Result.ok({ "sku": sku, "mock": true }))
