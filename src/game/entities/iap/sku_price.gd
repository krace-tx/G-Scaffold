class_name SkuPrice
extends Resource

## 商店商品展示价格缓存（product_id → 展示价格文字，如 "USD 0.99"）。
## 由 [IapClient] 从本地缓存恢复，并在商店查询后刷新。

@export var prices: Dictionary = {}


const _STORAGE_ITEM_KEY := &"sku_price"


#region Codec
func encode() -> Dictionary:
	return { "prices": prices }


static func decode(encoded: Dictionary) -> SkuPrice:
	var res := SkuPrice.new()
	if encoded.get("prices") is Dictionary:
		res.prices = encoded["prices"]
	return res
#endregion


#region Persist Route
static func storage_item() -> StorageItem:
	var item := StorageItem.new()
	item.key_id = _STORAGE_ITEM_KEY
	item.disk_path = StorageCatalog.SKU_PRICE
	return item
#endregion
