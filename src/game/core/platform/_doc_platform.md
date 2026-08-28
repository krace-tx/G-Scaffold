# Platform

## 核心

平台服务层负责连接第三方平台能力（广告 AdMob、埋点 Firebase、应用内购买 IAP、第三方登录 Google/Apple、系统原生分享）。
提供跨平台自适应与降级机制（真机接入原生 SDK，编辑器/PC 环境自动走 Mock），统一通过 Autoload `Platform` 向业务层暴露高内聚的 Client 门面。
不承载核心游戏拼图逻辑，不直接管理玩家游戏关卡与存档资产。

---

## 细节

- 入口：通过全局 Autoload `Platform` 挂载各子系统 Client 门面（`Platform.ad`、`Platform.analytics`、`Platform.iap`、`Platform.auth`、`Platform.share`）。
- 启动调度：由 `GamePlatformStage` 统一调用各 Client 的 `initialize()`。采用非阻塞降级设计，单个 SDK 缺失或失败只记 Warn，不阻断启动。
- 适配器分流：各 Client 内部根据运行平台（Android/iOS/Editor）挂载对应的 Native Adapter 或 Mock Adapter，业务调用处无需判断平台。
- 多策略埋点：`AnalyticsClient` 借鉴 `PersistService` 架构，由 `AnalyticsPipeline` 根据 `ReportMode`（`ALL`, `FIREBASE_ONLY`, `SERVER_ONLY`, `DIRECT_SERVER`）将事件分发至对应驱动层（`FirebaseDriver`、`ServerQueueDriver`），兼顾实时打点与弱网离线可靠性。
- 价格缓存：`IapClient` 启动时优先从 `user://cache/sku_price.json` 异步恢复商品展示价格，连接商店后异步拉取并刷新。

```text
src/game/core/platform/
├── _doc_platform.md                    # 平台服务层架构与使用说明
├── ads/                               # 广告子系统 (流水线架构)
│   ├── mode/
│   │   └── ad_types.gd                # 广告类型 (AdType) 与状态 (AdState)
│   ├── pipeline/
│   │   ├── ad_pipeline.gd             # 调度流水线：ATT 授权流 ➔ 驱动激活 ➔ 广告调度
│   │   └── att_controller.gd          # iOS ATT 授权弹窗控制与状态持久化
│   ├── drivers/
│   │   ├── ad_driver.gd               # 广告驱动接口基类
│   │   ├── admob_ad_driver.gd         # AdMob 原生 SDK 加载、生命周期与安全重试
│   │   └── mock_ad_driver.gd          # PC/编辑器 Mock 广告驱动
│   └── ad_client.gd                   # 广告对外门面客户端 (Platform.ad)
├── analytics/                         # 统计打点子系统 (管道架构)
│   ├── mode/
│   │   ├── analytics_channel.gd       # 渠道位掩码 (FIREBASE, SERVER, ALL)
│   │   └── report_mode.gd             # 上报策略模式 (ALL, FIREBASE_ONLY, SERVER_ONLY, DIRECT_SERVER)
│   ├── pipeline/
│   │   ├── analytics_pipeline.gd      # 调度管道：按 ReportMode 路由驱动分发
│   │   ├── event_queue.gd             # 离线事件本地持久化缓冲队列
│   │   └── event_reporter.gd          # 定时批量上报器
│   ├── drivers/
│   │   ├── analytics_driver.gd        # 驱动接口基类
│   │   ├── firebase_driver.gd         # Firebase 实时打点驱动
│   │   ├── server_queue_driver.gd     # 自研服务端缓冲上报驱动
│   │   └── mock_analytics_driver.gd   # Mock 调试驱动
│   └── analytics_client.gd            # 埋点对外门面客户端 (Platform.analytics)
├── iap/                               # 内购结算子系统
│   ├── store_adapter.gd               # godot-iap 原生商店与交易适配器
│   ├── mock_store_adapter.gd          # Mock 商店适配器
│   └── iap_client.gd                  # 内购对外门面客户端 (Platform.iap)
├── auth/                              # 认证登录子系统 (流水线架构)
│   ├── mode/
│   │   └── auth_channel.gd            # 渠道枚举 (AUTO, GOOGLE, APPLE, MOCK)
│   ├── pipeline/
│   │   ├── auth_pipeline.gd           # 调度流水线：渠道选择 ➔ 原生授权 ➔ 验签换Token ➔ 产出实体
│   │   └── firebase_token_client.gd   # 换 Token 客户端 (未来可平滑替换为 ServerTokenClient)
│   ├── providers/
│   │   ├── auth_provider.gd           # Provider 抽象基类
│   │   ├── google_auth_provider.gd    # Google 原生登录 Provider (Android)
│   │   ├── apple_auth_provider.gd     # Apple 原生登录 Provider (iOS)
│   │   └── mock_auth_provider.gd      # Mock 登录 Provider (Editor/PC)
│   ├── auth_user.gd                   # 登录用户信息领域实体 (AuthUser)
│   └── auth_client.gd                 # 登录对外门面客户端 (Platform.auth)
└── share/                             # 系统分享子系统
    ├── native_share_adapter.gd        # 原生系统分享适配器
    ├── mock_share_adapter.gd          # Mock 分享适配器
    └── share_client.gd                # 分享对外门面客户端 (Platform.share)
```

---

## 样例

```gdscript
# 1. 播放激励视频并安全发奖
var ad_res: Result = await Platform.ad.show_rewarded(&"revive_placement")
if ad_res.is_ok():
	print("User earned reward!")
else:
	print("Ad dismissed or failed: ", ad_res.error)

# 2. 统计打点（默认全通道，亦可指定策略模式）
Platform.analytics.track(&"level_pass", { "level_id": 5, "duration": 120 })
Platform.analytics.track(&"click_button", { "btn": "settings" }, ReportMode.FIREBASE_ONLY)
Platform.analytics.track(&"coin_consumed", { "cost": 50 }, ReportMode.SERVER_ONLY)

# 3. 内购查询价格与购买
var price_text := Platform.iap.get_price("ad_free_item")
var pay_res: Result = await Platform.iap.purchase("ad_free_item")
if pay_res.is_ok():
	print("Purchase successful, order: ", pay_res.value)

# 4. 第三方登录与登出（异步 await 返回 Result，支持自动适配或指定渠道）
var auth_res: Result = await Platform.auth.login_async()
if auth_res.is_ok():
	var user: AuthUser = auth_res.value
	print("Logged in: ", user.uid, " email: ", user.email)
else:
	print("Login failed: ", auth_res.error)

# 登出账号
Platform.auth.logout()

# 5. 系统分享
Platform.share.share_screenshot("My Jigsaw Puzzle", "Check this out!", "I solved the puzzle!")
```
