class_name Result
extends RefCounted

## 可失败操作的统一返回类型。
## 强制调用方显式处理成功与失败分支，避免错误被静默吞没。

#region Exports & State
var _ok: bool = false
var value: Variant = null   ## 成功时的负载;失败时为 null
var error: Variant = null   ## 失败时的原因(字符串或错误对象);成功时为 null
#endregion

#region Public API
## 构造一个成功结果,可携带负载 [param p_value]。
static func ok(p_value: Variant = null) -> Result:
	var r := Result.new()
	r._ok = true
	r.value = p_value
	return r


## 构造一个失败结果,携带失败原因 [param p_error]。
static func err(p_error: Variant = "") -> Result:
	var r := Result.new()
	r._ok = false
	r.error = p_error
	return r


## 是否为成功结果。
func is_ok() -> bool:
	return _ok


## 是否为失败结果。
func is_err() -> bool:
	return not _ok


## 成功时返回负载,失败时返回 [param default],不触发错误。
func value_or(default: Variant) -> Variant:
	return value if _ok else default
#endregion

#region Internal
func _to_string() -> String:
	return "Result.ok(%s)" % value if _ok else "Result.err(%s)" % error
#endregion
