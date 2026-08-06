extends RefCounted

## 插件内部可失败操作返回类型(无 class_name,不注册到全局)。
##
## 仅供 Asset Groups 编辑器代码使用,与运行时 framework 的 Result 无关。

const _Self := preload("res://addons/asset_groups/internal/asset_group_result.gd")

var _ok: bool = false
var value: Variant = null
var error: Variant = null


static func ok(p_value: Variant = null) -> RefCounted:
	var r: RefCounted = _Self.new()
	r._ok = true
	r.value = p_value
	return r


static func err(p_error: Variant = "") -> RefCounted:
	var r: RefCounted = _Self.new()
	r._ok = false
	r.error = p_error
	return r


func is_ok() -> bool:
	return _ok


func is_err() -> bool:
	return not _ok


func value_or(default: Variant) -> Variant:
	return value if _ok else default
