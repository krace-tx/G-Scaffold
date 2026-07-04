class_name AnalyticsProviderFactory
extends RefCounted

## 按运行环境选择统计 provider 实现。目前真机也暂用 Null(打点落日志),接入真实
## 统计 SDK 时在此按 OS 分发,与 [AdProviderFactory] 对称。

## 创建当前环境对应的 [AnalyticsProvider]。
static func create() -> AnalyticsProvider:
	# TODO(SDK): 接入 Firebase / 神策等后,按 OS.get_name() 返回对应真实现。
	return NullAnalyticsProvider.new()
