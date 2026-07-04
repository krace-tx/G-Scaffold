class_name AdProviderFactory
extends RefCounted

## 按运行环境选择广告 provider 实现。这是防腐层的"入口":业务永远不在这里之外
## 判断平台。编辑器 / 不支持的平台一律 Null——保证 F5 与 CI 无头都能跑通全流程。

## 创建当前环境对应的 [AdProvider]。注意:即便返回真实现,若其 initialize 失败,
## PlatformService 仍会把它降级为 [NullAdProvider]。
static func create() -> AdProvider:
	if OS.has_feature("editor"):
		return NullAdProvider.new()
	match OS.get_name():
		"Android":
			return AdmobAndroidProvider.new()
		"iOS":
			return AdmobIOSProvider.new()
		_:
			return NullAdProvider.new()
