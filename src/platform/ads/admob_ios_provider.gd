class_name AdmobIOSProvider
extends AdProvider

## iOS 广告真实现【骨架】——SDK 接入时在此封装 iOS 插件调用。
##
## 与 [AdmobAndroidProvider] 对称:目前 initialize 返回 false → 自动降级为 NullAdProvider,
## 真机接入前 iOS 包也能照常运行。接入步骤见 docs/guides/add-a-platform-provider.md。

#region Public API
func initialize() -> bool:
	# TODO(SDK): 获取 iOS 广告插件单例、初始化、预加载。成功 true,失败 false(降级 Null)。
	App.log.warn("ads", "AdmobIOSProvider is a skeleton — not implemented, will downgrade")
	return false


func show_rewarded(_placement: StringName) -> AdResult:
	# TODO(SDK): 调 iOS 插件展示激励视频,await 回调结果。
	return AdResult.failed("AdmobIOSProvider not implemented")


func is_ready(_placement: StringName) -> bool:
	# TODO(SDK): 查询广告位就绪状态。
	return false
#endregion
