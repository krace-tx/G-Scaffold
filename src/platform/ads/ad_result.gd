class_name AdResult
extends RefCounted

## 一次广告请求的结果(值对象)。业务据此决定是否发奖:
## [code]if res.is_rewarded(): Bus.ad_reward_granted.emit(placement)[/code]

## 枚举需全限定为 [code]AdResult.Status[/code] 引用(见下)——class_name 脚本里
## 内部 enum 若被用作自身成员类型标注,不全限定会在 autoload 编译级联中触发幻象报错。
enum Status { REWARDED, DISMISSED, FAILED, NOT_READY }

#region Exports & State
var status: AdResult.Status = AdResult.Status.FAILED
var message: String = ""   ## 仅 FAILED 时有意义
#endregion

#region Public API
## 用户看完广告,应发奖。
static func rewarded() -> AdResult:
	var r := AdResult.new()
	r.status = AdResult.Status.REWARDED
	return r


## 用户中途关闭,未达发奖条件。
static func dismissed() -> AdResult:
	var r := AdResult.new()
	r.status = AdResult.Status.DISMISSED
	return r


## 展示失败(无填充 / SDK 报错等),[param msg] 记录原因。
static func failed(msg: String = "") -> AdResult:
	var r := AdResult.new()
	r.status = AdResult.Status.FAILED
	r.message = msg
	return r


## 广告位尚未就绪(未预加载)。
static func not_ready() -> AdResult:
	var r := AdResult.new()
	r.status = AdResult.Status.NOT_READY
	return r


## 是否达到发奖条件(用户完整看完)。
func is_rewarded() -> bool:
	return status == AdResult.Status.REWARDED
#endregion
