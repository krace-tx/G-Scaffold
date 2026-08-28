class_name AnalyticsDriver
extends RefCounted

## 统计打点驱动抽象基类。
## 为各打点平台与通道（Firebase、自研服务端队列、Mock 等）提供统一标准接口。


func initialize() -> Result:
	return Result.ok()


## 上报自定义业务事件。
func log_event(_event_name: StringName, _params: Dictionary) -> void:
	pass


## 设置用户画像属性。
func set_user_property(_prop_name: String, _value: Variant) -> void:
	pass
