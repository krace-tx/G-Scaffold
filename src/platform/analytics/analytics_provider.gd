@abstract
class_name AnalyticsProvider
extends PlatformProvider

## 统计打点契约。业务只认 [method track],不认具体 SDK(Firebase / 神策……)。

## 上报一个事件。[param event] 事件名(如 &"level_start");[param params] 附加参数。
## 打点是"发出即忘"语义,不返回结果、不 await——不能因为打点失败拖慢业务。
@abstract
func track(event: StringName, params: Dictionary) -> void
