class_name AuthChannel
extends RefCounted

## 认证登录渠道枚举。
## 调用形如 [code]AuthChannel.AUTO[/code] 或 [code]AuthChannel.GOOGLE[/code]。

enum {
	AUTO,    ## 【默认】自动适配当前平台（Android 走 Google，iOS 走 Apple，其他平台走 Mock）
	GOOGLE,  ## Google 原生登录 (Android)
	APPLE,   ## Apple 原生登录 (iOS)
	MOCK,    ## Mock 模拟登录 (用于开发联调与测试)
}
