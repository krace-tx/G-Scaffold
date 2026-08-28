class_name AttController
extends RefCounted

## iOS ATT (App Tracking Transparency) 授权控制器。
## 协调原生 ATT 授权弹窗交互，并持久化记录授权状态至 [StorageCatalog.AD_ATT_FLAG]。

const _STORAGE_ITEM_KEY: StringName = &"ad_att_flag"

signal permission_completed(status: Dictionary)

var _is_requested := false


## 本实体的本地持久化路由描述项。
static func storage_item() -> StorageItem:
	var item := StorageItem.new()
	item.key_id = _STORAGE_ITEM_KEY
	item.disk_path = StorageCatalog.AD_ATT_FLAG
	return item


func is_requested() -> bool:
	return _is_requested


func load_state() -> void:
	if FileUtils.file_exists(StorageCatalog.AD_ATT_FLAG) or App.persist.has(_STORAGE_ITEM_KEY):
		_is_requested = true


func request_permission() -> void:
	if not Engine.has_singleton("GodotxAtt"):
		App.log.warn("AttController", "GodotxAtt singleton not found, fallback")
		_on_status_updated({ "status": "unavailable" })
		return

	var att = Engine.get_singleton("GodotxAtt")
	att.status_updated.connect(_on_status_updated, CONNECT_ONE_SHOT)
	att.request_permission()


func _on_status_updated(status: Dictionary) -> void:
	_is_requested = true
	var item := storage_item()
	App.persist.write_async(item, { "status": status.get("status", "unknown") })
	App.log.info("AttController", "ATT permission status resolved: %s" % JSON.stringify(status))
	permission_completed.emit(status)
