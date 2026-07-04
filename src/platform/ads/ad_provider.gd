@abstract
class_name AdProvider
extends PlatformProvider

## 广告能力契约。业务只认这个接口,不认具体 SDK(AdMob / 穿山甲……)。
## 契约只表达"业务需要什么",不映射任何 SDK 的 API 形状,防止 SDK 概念泄漏。
## 接入流程见 docs/guides/add-a-platform-provider.md。

## 展示激励视频,await 到用户看完 / 关闭 / 失败,返回 [AdResult]。
## [param placement] 为广告位标识(如 &"double_coins")。实现应自带超时,失败返回
## [method AdResult.failed],绝不无限挂起。
@abstract
func show_rewarded(placement: StringName) -> AdResult


## 指定广告位是否已预加载就绪。默认 false,子类可覆写。
func is_ready(_placement: StringName) -> bool:
	return false
