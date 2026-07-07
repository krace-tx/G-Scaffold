@tool
class_name RegistryResult
extends RefCounted

## 插件内可失败操作的统一返回类型。
##
## 与宿主项目的 [Result] 解耦,避免 [code]class_name[/code] 冲突。

#region Exports & State
var _ok: bool = false
var value: Variant = null
var error: Variant = null
#endregion

#region Public API
## 构造成功结果,可携带负载 [param p_value]。
static func ok(p_value: Variant = null) -> RegistryResult:
	var r := RegistryResult.new()
	r._ok = true
	r.value = p_value
	return r


## 构造失败结果,携带原因 [param p_error]。
static func err(p_error: Variant = "") -> RegistryResult:
	var r := RegistryResult.new()
	r._ok = false
	r.error = p_error
	return r


func is_ok() -> bool:
	return _ok


func is_err() -> bool:
	return not _ok
#endregion
