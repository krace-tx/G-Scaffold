class_name ReportMode
extends RefCounted

## 统计事件上报策略模式（定义事件的分发通道与投递方式）。[br]
## 调用形如 [code]ReportMode.ALL[/code] 或 [code]ReportMode.FIREBASE_ONLY[/code]。

enum {
	ALL,            ## 【默认】全通道分发：Firebase 实时通道 + 自研服务端离线缓冲队列
	FIREBASE_ONLY,  ## 仅上报 Firebase 实时通道（适合高频且无需服务端建表分析的 UI 交互事件）
	SERVER_ONLY,    ## 仅入队上报自研服务端（适合核心经济数值、防作弊校验、离线漏斗事件）
	DIRECT_SERVER,  ## 实时直接 HTTP 投递自研服务端（不走本地磁盘离线缓冲队列）
}
