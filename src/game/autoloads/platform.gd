extends Node

## 平台 SDK 业务层全局聚合根 (Autoload)。
## 集中挂载并持有与三方平台接入相关的客户端门面（广告、埋点、内购、登录、分享）。
## 启动时由 GamePlatformStage 统一调度完成各子系统的异步恢复与适配器初始化。

#region Platform Clients
## 广告子系统门面（激励视频、插屏、横幅、ATT 授权）
var ad: AdClient = AdClient.new()

## 统计埋点子系统门面（Firebase 实时打点 + 本地离线事件队列上报）
var analytics: AnalyticsClient = AnalyticsClient.new()

## 应用内购买子系统门面（商品价格缓存、发起购买与恢复购买）
var iap: IapClient = IapClient.new()

## 认证登录子系统门面（Google/Apple 原生登录 + Firebase 换 Token）
var auth: AuthClient = AuthClient.new()

## 系统分享子系统门面（文本、图片、纹理、屏幕截屏分享）
var share: ShareClient = ShareClient.new()
#endregion
