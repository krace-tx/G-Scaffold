class_name TimeService
extends RefCounted

## 权威时间源。
##
## 所有每日重置、广告冷却、活动倒计时必须用 [method now],**禁止直接读系统时钟**
## ——玩家改设备时间是移动端第一大作弊手段。见 docs/architecture/boot-sequence.md。
##
## 已校时(M4 登录握手拿到服务器时间后):基于服务器时间 + 本地单调 tick 推进,
## 玩家改系统时钟无效。未校时:退化为系统时钟且 [method is_trusted] 返回 false,
## 业务应据此拒绝执行敏感的时间相关逻辑。

#region Exports & State
var _synced: bool = false
var _sync_server_msec: int = 0   ## 校时那一刻的服务器 unix 毫秒
var _sync_tick_msec: int = 0     ## 校时那一刻的本地 Time.get_ticks_msec()
#endregion

#region Public API
## 当前 unix 时间(秒)。已校时→服务器时间+本地tick推进;未校时→系统时钟(不可信)。
func now() -> int:
	@warning_ignore("integer_division")   # 有意:毫秒→秒取整
	return now_msec() / 1000


## 当前 unix 时间(毫秒)。
func now_msec() -> int:
	if _synced:
		return _sync_server_msec + (Time.get_ticks_msec() - _sync_tick_msec)
	return int(Time.get_unix_time_from_system() * 1000.0)


## 用服务器时间校准(M4 登录握手成功后调用)。[param server_unix_msec] 为服务器 unix 毫秒。
## 校准后 [method now] 即基于服务器时间推进,与本地系统时钟解耦。
func sync_from_server(server_unix_msec: int) -> void:
	_sync_server_msec = server_unix_msec
	_sync_tick_msec = Time.get_ticks_msec()
	_synced = true


## 是否已用服务器时间校准。false 时 [method now] 的返回值来自系统时钟,不可信。
func is_trusted() -> bool:
	return _synced
#endregion
