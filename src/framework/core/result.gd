class_name Result
extends RefCounted

## 可失败操作的统一返回类型。
##
## [b]为什么这么设计[/b][br]
## GDScript 没有异常机制。传统做法是"返回 null 表示失败"或"用 bool + out 参数"，
## 两者都容易被调用方静默忽视(拿到 null 继续用导致崩溃,或忘记检查返回值)。
## Result 强制调用方显式分支(is_ok / is_err),失败原因也一并携带,无法吞错。
##
## [b]如何使用[/b][br]
## 所有可预期失败的操作(网络、存档、资源加载、业务逻辑校验)返回 Result。
## 调用方必须检查结果,不允许"假设成功"。
##
## [b]基础用法[/b]:[br]
## [codeblock]
## # 网络请求
## var res := await App.net.post_request("/rank/list", params)
## if res.is_err():
##     App.log.warn("rank", "拉取失败: %s" % res.error)
##     return
## var rank_data := res.value as Dictionary
## _show_rank(rank_data)
## [/codeblock]
##
## [b]链式处理(多步可能失败)[/b]:[br]
## [codeblock]
## func initialize_game() -> Result:
##     var config_res := App.config.load_local()
##     if config_res.is_err(): return config_res  # 传播失败
##     var network_res := await App.net.connect()
##     if network_res.is_err(): return network_res
##     return Result.ok()  # 全部成功
## [/codeblock]
##
## [b]不要这样做[/b]:[br]
## [codeblock]
## # ❌ 静默吞错(最常见的反面例子)
## var res := await fetch_data()
## use(res.value)  # 如果 res.is_err(),value 是 null,这会崩溃
##
## # ❌ 用异常来做错误控制(GDScript 没有异常)
## # 改用 Result 的 is_err 分支
## [/codeblock]
##
## 详见 docs/conventions/coding-style.md 第四章第 5 条。

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
