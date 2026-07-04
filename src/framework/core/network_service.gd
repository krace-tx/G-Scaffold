class_name NetworkService
extends Node

## 传输层:HTTP 请求池 + 超时 + 指数退避重试 + 鉴权头注入,统一返回 [Result]。
##
## 提供 Mock 模式(本地 JSON 应答,不发真实请求),让编辑器/CI 无头在没有后端的
## 情况下也能跑通"登录 → 校时 → 拉远程配置"演示链路。见 docs/modules/network-service.md。
##
## 真实模式下网络异常(断网/超时/连接失败)一律走重试→最终返回 err,绝不无限挂起
## 卡死游戏;4xx 客户端错误不重试(重试无意义)。

#region Constants & Enums
## 需要重试的 [enum HTTPRequest.Result]:网络层失败,重试可能恢复。
const _RETRYABLE_RESULTS: Array[int] = [
	HTTPRequest.RESULT_CANT_CONNECT,
	HTTPRequest.RESULT_CANT_RESOLVE,
	HTTPRequest.RESULT_CONNECTION_ERROR,
	HTTPRequest.RESULT_TIMEOUT,
]
#endregion

#region Exports & State
## 单次请求超时(秒)。测试可调小以加速验证。
var request_timeout: float = 5.0
## 网络层失败时的最大重试次数(不含首次尝试)。
var max_retries: int = 2
## 指数退避基数(秒):第 N 次重试等待 base * 2^(N-1)。
var retry_backoff_base: float = 0.3

var _base_url: String = ""
var _auth_token: String = ""

## Mock 模式:true 时不发真实请求,从 [member _mock_responses] 查表应答。
var _mock_enabled: bool = false
## path → Dictionary(直接作为成功负载)或 Callable(method,path,body)->Result(自定义,含失败模拟)。
var _mock_responses: Dictionary = {}

## 空闲的 HTTPRequest 节点池,避免每次请求都新建/销毁子节点。
var _free_pool: Array[HTTPRequest] = []
#endregion

#region Public API
## 配置真实后端(真机模式)。[param base_url] 形如 "https://api.example.com"。
func configure(base_url: String, auth_token: String = "") -> void:
	_base_url = base_url
	_auth_token = auth_token


## 开启 Mock 模式,[param responses] 为 path → 响应体(Dictionary)或
## Callable(method: String, path: String, body: Dictionary) -> Result(用于模拟失败)。
func enable_mock(responses: Dictionary) -> void:
	_mock_enabled = true
	_mock_responses = responses


func get_request(path: String, params: Dictionary = {}) -> Result:
	return await _request("GET", path, params)


func post(path: String, body: Dictionary = {}) -> Result:
	return await _request("POST", path, body)


## 登录 + 校时 + 拉远程配置的一次性握手流程(Bootstrap 阶段 4 调用)。
## 成功:token 存入本服务、[method TimeService.sync_from_server] 已调用、
## [method ConfigService.apply_remote] 已调用。任一步失败即返回 err,调用方应
## 降级为已有的本地缓存/默认值,不阻断启动。
func login_and_sync() -> Result:
	var login_res := await post("/auth/login", {})
	if login_res.is_err():
		return login_res

	var payload: Dictionary = login_res.value
	_auth_token = str(payload.get("token", ""))
	App.time.sync_from_server(int(payload.get("server_time_msec", 0)))

	var cfg_res := await get_request("/config/remote")
	if cfg_res.is_err():
		return cfg_res

	App.config.apply_remote(cfg_res.value as Dictionary)
	return Result.ok()
#endregion

#region Internal
## 统一请求入口:Mock 分支 or 真实请求(含重试)。
func _request(method: String, path: String, body: Dictionary) -> Result:
	if _mock_enabled:
		return await _mock_request(method, path, body)
	return await _real_request_with_retry(method, path, body)


## Mock 应答:模拟一帧延迟后按 path 查表,不发真实请求。
func _mock_request(method: String, path: String, body: Dictionary) -> Result:
	await get_tree().process_frame
	if not _mock_responses.has(path):
		return Result.err("mock: no response registered for %s" % path)

	var entry: Variant = _mock_responses[path]
	if entry is Callable:
		return await (entry as Callable).call(method, path, body)
	return Result.ok(entry)


## 真实请求 + 重试:网络层失败(见 _RETRYABLE_RESULTS)或 5xx 才重试,4xx 直接返回 err。
func _real_request_with_retry(method: String, path: String, body: Dictionary) -> Result:
	var last_res := Result.err("unreachable")
	for attempt in range(max_retries + 1):
		last_res = await _real_request_once(method, path, body)
		if last_res.is_ok():
			return last_res

		var retryable: bool = last_res.error is Dictionary and (last_res.error as Dictionary).get("retryable", false)
		if not retryable or attempt >= max_retries:
			break
		await get_tree().create_timer(retry_backoff_base * pow(2, attempt)).timeout

	var msg: Variant = (last_res.error as Dictionary).get("message", last_res.error) if last_res.error is Dictionary else last_res.error
	return Result.err(msg)


## 发起单次真实 HTTP 请求,返回 Result(err 时 error 为 {message,retryable} 供上层判断重试)。
func _real_request_once(method: String, path: String, body: Dictionary) -> Result:
	var hr := _acquire_request()
	hr.timeout = request_timeout

	var headers := PackedStringArray(["Content-Type: application/json"])
	if not _auth_token.is_empty():
		headers.append("Authorization: Bearer %s" % _auth_token)

	var http_method := HTTPClient.METHOD_POST if method == "POST" else HTTPClient.METHOD_GET
	var body_json := JSON.stringify(body) if method == "POST" else ""
	var err := hr.request(_base_url + path, headers, http_method, body_json)
	if err != OK:
		_release_request(hr)
		return Result.err({"message": "request() failed to start (err=%d)" % err, "retryable": true})

	var response: Array = await hr.request_completed
	_release_request(hr)

	var result: int = response[0]
	var code: int = response[1]
	var raw_body: PackedByteArray = response[3]

	if result in _RETRYABLE_RESULTS:
		return Result.err({"message": "network error (result=%d)" % result, "retryable": true})
	if code >= 500:
		return Result.err({"message": "server error (code=%d)" % code, "retryable": true})
	if code < 200 or code >= 300:
		return Result.err({"message": "http error (code=%d)" % code, "retryable": false})

	var parsed: Variant = JSON.parse_string(raw_body.get_string_from_utf8())
	return Result.ok(parsed if parsed != null else {})


## 从空闲池取一个 HTTPRequest,没有则新建并挂到自己下面(必须在树上才能工作)。
func _acquire_request() -> HTTPRequest:
	if not _free_pool.is_empty():
		return _free_pool.pop_back()
	var hr := HTTPRequest.new()
	NodeUtils.mount_required(hr, self, "HTTPRequest_%d" % get_child_count())
	return hr


## 请求用完放回空闲池以复用,避免频繁创建/销毁节点。
func _release_request(hr: HTTPRequest) -> void:
	_free_pool.append(hr)
#endregion
