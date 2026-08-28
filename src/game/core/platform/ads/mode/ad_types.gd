class_name AdTypes
extends RefCounted

## 广告类型与状态枚举定义。

enum AdType {
	REWARDED,      ## 激励视频广告
	INTERSTITIAL,  ## 插屏广告
	BANNER,        ## 横幅广告
}

enum AdState {
	NOT_LOADED,    ## 未加载 / 空闲
	LOADING,       ## 正在异步加载中
	READY,         ## 已就绪，可随时播放
	SHOWING,       ## 正在屏幕展示中
}
