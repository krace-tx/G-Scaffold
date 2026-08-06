class_name NetworkService
extends Node

## 传输层:HTTP 请求池 + 超时 + 指数退避重试 + 鉴权头注入,统一返回 [Result]。
##
## [b]为什么这么设计[/b][br]
## 本服务提供高容错、无卡死的网络调用。网络层失败或 5xx 服务端错误会自动启动指数退避重试，
## 4xx 客户端错误则立即返回。所有接口通过 [Result] 强类型返回，避免 null 崩溃。
##
## [b]API 使用样例[/b][br]
## [codeblock]
## # 1. 常规 POST 请求
## var params := { "user_id": "123" }
## var res := await App.net.post_request("/api/v1/user/profile", params)
## if res.is_err():
##     App.log.error("NetworkService", "获取档案失败: %s" % res.error)
##     return
## var profile_data := res.value as Dictionary
## 
## # 2. 文件/图片下载 (带进度回调)
## var on_progress := func(downloaded: int, total: int):
##     print("下载进度: %d/%d" % [downloaded, total])
## var dl_res := await App.net.download_file("https://example.com/bg.png", "user://cache/bg.png", on_progress)
## if dl_res.is_ok():
##     print("文件已成功保存至: ", dl_res.value)
##
## # 3. 头像/文件上传 (Multipart)
## var file_bytes := FileAccess.get_file_as_bytes("user://avatar.png")
## var upload_res := await App.net.upload_file("/api/v1/avatar", "file", file_bytes, "avatar.png", "image/png")
## if upload_res.is_ok():
##     var avatar_url = upload_res.value.get("avatar_url")
## [/codeblock]

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

## 空闲的 HTTPRequest 节点池,避免每次请求都新建/销毁子节点。
var _free_pool: Array[HTTPRequest] = []
#endregion

#region Public API
## 配置真实后端(真机模式)。[param base_url] 形如 "https://api.example.com"。
func configure(base_url: String, auth_token: String = "") -> void:
	_base_url = base_url
	_auth_token = auth_token

func get_request(path: String, params: Dictionary = {}) -> Result:
	return await _request("GET", path, params)

func post_request(path: String, body: Dictionary = {}) -> Result:
	return await _request("POST", path, body)

## POST multipart/form-data 单文件上传，统一返回 [Result]。
func upload_file(path: String, field_name: String, file_bytes: PackedByteArray, filename: String, mime_type: String, custom_headers: PackedStringArray = [], timeout_sec: float = 15.0) -> Result:
	if file_bytes.is_empty():
		return Result.err("Empty file bytes")

	var boundary := "----GodotFormBoundary%d" % Time.get_ticks_msec()
	var crlf := "\r\n"
	var body := PackedByteArray()
	var header := (
		"--%s%s"
		+ "Content-Disposition: form-data; name=\"%s\"; filename=\"%s\"%s"
		+ "Content-Type: %s%s%s"
	) % [boundary, crlf, field_name, filename, crlf, mime_type, crlf, crlf]
	body.append_array(header.to_utf8_buffer())
	body.append_array(file_bytes)
	body.append_array(crlf.to_utf8_buffer())
	body.append_array(("--%s--%s" % [boundary, crlf]).to_utf8_buffer())

	var headers := PackedStringArray([
		"Content-Type: multipart/form-data; boundary=%s" % boundary,
		"Content-Length: %d" % body.size(),
	])
	headers.append_array(custom_headers)
	if not _auth_token.is_empty():
		headers.append("Authorization: Bearer %s" % _auth_token)

	var hr := HTTPRequest.new()
	hr.timeout = timeout_sec
	NodeUtils.mount_required(hr, self, "HTTPUpload_%d" % get_child_count())

	var final_url := path
	if not path.begins_with("http://") and not path.begins_with("https://"):
		final_url = _base_url + path

	var err := hr.request_raw(final_url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		hr.queue_free()
		return Result.err("Failed to initiate upload (Godot error code: %d)" % err)

	var response: Array = await hr.request_completed
	hr.queue_free()

	var result_code: int = response[0]
	var status_code: int = response[1]
	var resp_body: PackedByteArray = response[3]

	if result_code != HTTPRequest.RESULT_SUCCESS:
		return Result.err("Upload failed (Godot internal error code: %d, HTTP status: %d)" % [result_code, status_code])

	var parsed: Variant = JSON.parse_string(resp_body.get_string_from_utf8())
	if status_code < 200 or status_code >= 300:
		return Result.err("Upload failed (Godot result code: %d, HTTP status: %d)" % [result_code, status_code])

	return Result.ok(parsed if parsed != null else {})

## 下载文件到本地磁盘，支持进度回调。
func download_file(url: String, save_path: String, on_progress: Callable = Callable(), custom_headers: PackedStringArray = []) -> Result:
	var hr := HTTPRequest.new()
	hr.timeout = 0
	hr.use_threads = true
	hr.download_file = save_path
	NodeUtils.mount_required(hr, self, "HTTPDownload_%d" % get_child_count())

	var headers := PackedStringArray(["Content-Type: application/json"])
	headers.append_array(custom_headers)

	var final_url := url
	if not url.begins_with("http://") and not url.begins_with("https://"):
		final_url = _base_url + url

	var err := hr.request(final_url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		hr.queue_free()
		return Result.err("Failed to initiate download (Godot error code: %d)" % err)

	var timer: Timer = null
	if on_progress.is_valid():
		timer = Timer.new()
		timer.wait_time = 0.2
		timer.autostart = true
		timer.one_shot = false
		NodeUtils.mount_required(timer, self, "HTTPDownloadTimer_%d" % get_child_count())
		timer.timeout.connect(func() -> void:
			if is_instance_valid(hr):
				on_progress.call(
					hr.get_downloaded_bytes(),
					hr.get_body_size()
				)
		)

	var response: Array = await hr.request_completed

	if is_instance_valid(timer):
		timer.stop()
		timer.queue_free()
	if is_instance_valid(hr):
		hr.queue_free()

	var result_code: int = response[0]
	var status_code: int = response[1]

	if result_code != HTTPRequest.RESULT_SUCCESS:
		return Result.err("Download failed (Godot internal error code: %d, HTTP status: %d)" % [result_code, status_code])

	if status_code < 200 or status_code >= 300:
		return Result.err("Download failed (HTTP status: %d)" % status_code)

	return Result.ok(save_path)

## 下载文件到本地并校验 MD5
func download_file_with_md5(url: String, save_path: String, expected_md5: String) -> Result:
	if url.is_empty() or expected_md5.is_empty():
		return Result.err("Invalid url or md5")

	var save_dir := save_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(save_dir):
		if DirAccess.make_dir_recursive_absolute(save_dir) != OK:
			return Result.err("Failed to create directory: %s" % save_dir)

	var res := await download_file(url, save_path)
	if res.is_err():
		return res

	if not FileAccess.file_exists(save_path):
		return Result.err("Downloaded file not found at: %s" % save_path)

	var file_md5 := FileAccess.get_md5(save_path)
	if file_md5 != expected_md5:
		DirAccess.remove_absolute(save_path)
		return Result.err("MD5 mismatch (expected: %s, got: %s)" % [expected_md5, file_md5])

	return Result.ok(save_path)
#endregion

#region Internal
## 统一请求入口(含重试):网络层失败(见 _RETRYABLE_RESULTS)或 5xx 才重试,4xx 直接返回 err。
func _request(method: String, path: String, body: Dictionary) -> Result:
	var last_res := Result.err("unreachable")
	for attempt in range(max_retries + 1):
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
			last_res = Result.err({"message": "request() failed to start (err=%d)" % err, "retryable": true})
		else:
			var response: Array = await hr.request_completed
			_release_request(hr)

			var result: int = response[0]
			var code: int = response[1]
			var raw_body: PackedByteArray = response[3]

			if result in _RETRYABLE_RESULTS:
				last_res = Result.err({"message": "network error (result=%d)" % result, "retryable": true})
			elif code >= 500:
				last_res = Result.err({"message": "server error (code=%d)" % code, "retryable": true})
			elif code < 200 or code >= 300:
				last_res = Result.err({"message": "http error (code=%d)" % code, "retryable": false})
			else:
				var parsed: Variant = JSON.parse_string(raw_body.get_string_from_utf8())
				return Result.ok(parsed if parsed != null else {})

		var retryable: bool = last_res.error is Dictionary and (last_res.error as Dictionary).get("retryable", false)
		if not retryable or attempt >= max_retries:
			break
		await get_tree().create_timer(retry_backoff_base * pow(2, attempt)).timeout

	var msg: Variant = (last_res.error as Dictionary).get("message", last_res.error) if last_res.error is Dictionary else last_res.error
	return Result.err(msg)

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
