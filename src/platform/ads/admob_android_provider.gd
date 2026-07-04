class_name AdmobAndroidProvider
extends AdProvider

## Android 广告真实现【骨架】——SDK 接入时在此封装 JNISingleton 调用。
##
## 目前所有方法都是占位:initialize 返回 false,于是 PlatformService 会自动降级为
## NullAdProvider。这样在真机接入 AdMob 之前,Android 包也能照常运行(走 Null 路径)。
## 接入步骤见 docs/guides/add-a-platform-provider.md。

#region Public API
func initialize() -> bool:
	# TODO(SDK): 获取 AdMob 的 JNISingleton、MobileAds.initialize、预加载广告位。
	#   成功返回 true;拿不到 singleton / 初始化失败返回 false(自动降级 Null)。
	App.log.warn("ads", "AdmobAndroidProvider is a skeleton — not implemented, will downgrade")
	return false


func show_rewarded(_placement: StringName) -> AdResult:
	# TODO(SDK): 调 JNISingleton 展示激励视频,connect 其回调信号,await 到结果。
	return AdResult.failed("AdmobAndroidProvider not implemented")


func is_ready(_placement: StringName) -> bool:
	# TODO(SDK): 查询该广告位是否已加载。
	return false
#endregion
