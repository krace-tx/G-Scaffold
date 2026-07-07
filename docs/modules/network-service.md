# NetworkService 模块文档

> status: active | 最后更新: 2026-07-04 | 代码位置: `res://src/framework/core/network_service.gd`

## 职责与边界

**做什么**:HTTP 传输层。请求池(复用 HTTPRequest 节点)、超时、指数退避重试、鉴权头注入,统一返回 [Result]。提供 `login_and_sync()` 高层握手:登录 → 用服务器时间校准 [TimeService] → 拉远程配置应用到 [ConfigService]。提供 Mock 模式,让编辑器/CI 无头在没有真实后端时也能跑通整条链路。

**明确不做什么**:
- 不定义业务接口 schema——具体项目在 `path` 和 body/响应结构上自行扩展
- 不做长连接/WebSocket——纯 HTTP 请求-响应,长连接是另一个服务的事(未来按需加)
- 不替 ConfigService/TimeService 做校验——`login_and_sync` 只是编排,数据校验在各服务内部

## 公开 API

```gdscript
func configure(base_url: String, auth_token: String = "") -> void   # 真机模式:接真实后端
func enable_mock(responses: Dictionary) -> void                      # Mock 模式:path -> 响应体/Callable
func get_request(path: String, params: Dictionary = {}) -> Result   # 异步
func post(path: String, body: Dictionary = {}) -> Result             # 异步
func login_and_sync() -> Result                                      # 登录+校时+拉配置一次性握手
```

可调超时/重试(非 const,便于测试调小):`request_timeout`(默认 5s)、`max_retries`(默认 2)、`retry_backoff_base`(默认 0.3s,指数退避)。

## Mock 模式

`enable_mock({path: response})`——`response` 可以是:
- `Dictionary`:直接作为成功负载返回(`Result.ok(response)`)
- `Callable(method, path, body) -> Result`:自定义逻辑,可模拟失败分支

未注册的 path 返回 `Result.err(...)`。`NetworkStage` 默认用 Mock 演示完整链路(见 `network_stage.gd` 的 `_demo_mock_responses`);接入真实后端后改用 `configure()`。

## 重试策略

只重试**网络层失败**(连接失败/超时/DNS 失败)和 **5xx 服务器错误**;**4xx 客户端错误不重试**(重试无意义,直接返回 err)。重试间隔指数退避:第 N 次等待 `retry_backoff_base * 2^(N-1)`。超过 `max_retries` 后返回最后一次的错误。

## Bus 事件

无。`login_and_sync` 的结果通过返回值传递,不发总线事件(YAGNI,需要时再加)。

## 依赖

- 依赖:`App.log`、`App.time`(`sync_from_server`)、`App.config`(`apply_remote`)
- 初始化时机:`NetworkStage`;`App._on_app_resumed` 恢复前台时重新握手(fire-and-forget,失败只记 warn)

## 持有的数据

- `_free_pool`:HTTPRequest 节点复用池,进程生命周期存在
- `_auth_token`:登录后写入,后续请求自动带 `Authorization: Bearer`

## 失败策略

- Mock 模式下未注册 path:`err`,不崩
- 真实模式网络层失败/5xx:重试至 `max_retries`,仍失败返回 `err`
- 真实模式 4xx:立即返回 `err`,不重试
- `login_and_sync` 任一步失败:整体返回 `err`;`NetworkStage` 使用 `DEGRADE`,降级为已有的本地缓存/默认值,**不阻断启动**

## 测试要点

- 已无头验证(2026-07-04,9 项):Mock 完整握手(登录→校时→配置应用)、Mock 缺失 path、Mock Callable 失败分支、**真实请求打不可路由地址在 5s 内返回 err(不卡死)**
- 后续单测(M6):重试次数与退避间隔精确计时、鉴权头注入、请求池复用不泄漏
