class_name Result 
extends RefCounted

## 可失败操作的统一返回类型。
##
## GDScript 没有异常,所有可预期失败的操作返回 Result,而不是抛错或返回
## 裸 null。调用方用 [method is_ok] / [method is_err] 分支,禁止静默吞错。
## 详见 docs/conventions/coding-style.md 第 4 条。
##
## [codeblock]
## var res := await App.net.post("/rank/list", params)
## if res.is_err():
##     App.log.warn("rank", "拉取失败: %s" % res.error)
##     return
## _show_rank(res.value)
## [/codeblock]

var _ok: bool = false
var value: Variant = null   ## 成功时的负载;失败时为 null
var error: Variant = null   ## 失败时的原因(字符串或错误对象);成功时为 null


## 构造一个成功结果,可携带负载。
static func ok(p_value: Variant = null) -> Result:
	var r := Result.new()
	r._ok = true
	r.value = p_value
	return r


## 构造一个失败结果,携带失败原因。
static func err(p_error: Variant = "") -> Result:
	var r := Result.new()
	r._ok = false
	r.error = p_error
	return r


func is_ok() -> bool:
	return _ok


func is_err() -> bool:
	return not _ok


## 成功时返回负载,失败时返回 [param default],不触发错误。
func value_or(default: Variant) -> Variant:
	return value if _ok else default


func _to_string() -> String:
	return "Result.ok(%s)" % value if _ok else "Result.err(%s)" % error
