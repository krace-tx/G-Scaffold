class_name NetworkService
extends Node

## HTTP 传输：请求池、超时、指数退避重试、鉴权头；统一返回 [Result]。
## 调用方必须 [code]await[/code]；[param url] 传完整地址，环境差异由业务配置。
## 网络层失败或 5xx 才重试；4xx 立即失败。

#region Constants & Enums
## 可重试的引擎结果码（连不上 / 解析失败 / 断线 / 超时）。
const _RETRYABLE_RESULTS: Array[int] = [
	HTTPRequest.RESULT_CANT_CONNECT,
	HTTPRequest.RESULT_CANT_RESOLVE,
	HTTPRequest.RESULT_CONNECTION_ERROR,
	HTTPRequest.RESULT_TIMEOUT,
]
#endregion

#region State
## 单次请求超时（秒）。
var request_timeout: float = 5.0
## 网络层失败时的最大重试次数（不含首次）。
var max_retries: int = 2
## 退避基数（秒）：第 N 次重试等待 [code]base * 2^(N-1)[/code]。
var retry_backoff_base: float = 0.3

var _auth_token: String = ""
## 空闲 [HTTPRequest] 池，避免每次新建子节点。
var _free_pool: Array[HTTPRequest] = []
#endregion

#region Public API
## 设置鉴权 Token；后续请求自动带 [code]Authorization: Bearer[/code]。
func set_auth_token(token: String) -> void:
	_auth_token = token


## GET。[param url] 为完整地址。
func get_request(url: String, params: Dictionary = {}) -> Result:
	return await _request("GET", url, params)


## POST。[param url] 为完整地址。
func post_request(url: String, body: Dictionary = {}) -> Result:
	return await _request("POST", url, body)


## POST multipart 单文件上传。[param url] 为完整地址。成功 value 为 JSON 或空 Dictionary。
func upload_file(url: String, field_name: String, file_bytes: PackedByteArray, filename: String, mime_type: String, custom_headers: PackedStringArray = [], timeout_sec: float = 15.0) -> Result:
	if file_bytes.is_empty():
		return Result.err("Upload failed: file bytes are empty.")

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

	var err := hr.request_raw(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		hr.queue_free()
		return Result.err("Upload failed: could not start request (%d)." % err)

	var response: Array = await hr.request_completed
	hr.queue_free()

	var result_code: int = response[0]
	var status_code: int = response[1]
	var resp_body: PackedByteArray = response[3]

	if result_code != HTTPRequest.RESULT_SUCCESS:
		return Result.err("Upload failed: transport error %d (HTTP %d)." % [result_code, status_code])

	var parsed: Variant = JSON.parse_string(resp_body.get_string_from_utf8())
	if status_code < 200 or status_code >= 300:
		return Result.err("Upload failed: HTTP %d." % status_code)

	return Result.ok(parsed if parsed != null else {})


## 下载到本地。[param url] 为完整地址。[param on_progress] 可选 [code](downloaded, total)[/code]。成功 value 为 [param save_path]。
func download_file(url: String, save_path: String, on_progress: Callable = Callable(), custom_headers: PackedStringArray = []) -> Result:
	var hr := HTTPRequest.new()
	hr.timeout = 0
	hr.use_threads = true
	hr.download_file = save_path
	NodeUtils.mount_required(hr, self, "HTTPDownload_%d" % get_child_count())

	var headers := PackedStringArray(["Content-Type: application/json"])
	headers.append_array(custom_headers)

	var err := hr.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		hr.queue_free()
		return Result.err("Download failed: could not start request (%d)." % err)

	var timer: Timer = null
	if on_progress.is_valid():
		timer = Timer.new()
		timer.wait_time = 0.2
		timer.autostart = true
		timer.one_shot = false
		NodeUtils.mount_required(timer, self, "HTTPDownloadTimer_%d" % get_child_count())
		timer.timeout.connect(func():
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
		return Result.err("Download failed: transport error %d (HTTP %d)." % [result_code, status_code])

	if status_code < 200 or status_code >= 300:
		return Result.err("Download failed: HTTP %d." % status_code)

	return Result.ok(save_path)


## 下载后校验 MD5；不匹配则删文件并失败。
func download_file_with_md5(url: String, save_path: String, expected_md5: String) -> Result:
	if url.is_empty() or expected_md5.is_empty():
		return Result.err("Download failed: url or md5 is empty.")

	var save_dir := save_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(save_dir):
		if DirAccess.make_dir_recursive_absolute(save_dir) != OK:
			return Result.err("Download failed: could not create directory '%s'." % save_dir)

	var res := await download_file(url, save_path)
	if res.is_err():
		return res

	if not FileAccess.file_exists(save_path):
		return Result.err("Download failed: file missing at '%s'." % save_path)

	var file_md5 := FileAccess.get_md5(save_path)
	if file_md5 != expected_md5:
		DirAccess.remove_absolute(save_path)
		return Result.err("Download failed: md5 mismatch (expected %s, got %s)." % [expected_md5, file_md5])

	return Result.ok(save_path)
#endregion

#region Internal
## 含重试。[param url] 须为完整地址。可重试错误暂记 Dictionary.retryable，耗尽后摊成字符串。
func _request(method: String, url: String, body: Dictionary) -> Result:
	var last_res := Result.err("Request failed: unknown error.")
	for attempt in range(max_retries + 1):
		var hr := _acquire_request()
		hr.timeout = request_timeout

		var headers := PackedStringArray(["Content-Type: application/json"])
		if not _auth_token.is_empty():
			headers.append("Authorization: Bearer %s" % _auth_token)

		var http_method := HTTPClient.METHOD_POST if method == "POST" else HTTPClient.METHOD_GET
		var body_json := JSON.stringify(body) if method == "POST" else ""
		var err := hr.request(url, headers, http_method, body_json)
		if err != OK:
			_release_request(hr)
			last_res = Result.err({"message": "Request failed: could not start (%d)." % err, "retryable": true})
		else:
			var response: Array = await hr.request_completed
			_release_request(hr)

			var result: int = response[0]
			var code: int = response[1]
			var raw_body: PackedByteArray = response[3]

			if result in _RETRYABLE_RESULTS:
				last_res = Result.err({"message": "Request failed: network error (%d)." % result, "retryable": true})
			elif code >= 500:
				last_res = Result.err({"message": "Request failed: server error (%d)." % code, "retryable": true})
			elif code < 200 or code >= 300:
				last_res = Result.err({"message": "Request failed: HTTP %d." % code, "retryable": false})
			else:
				var parsed: Variant = JSON.parse_string(raw_body.get_string_from_utf8())
				return Result.ok(parsed if parsed != null else {})

		var retryable: bool = last_res.error is Dictionary and (last_res.error as Dictionary).get("retryable", false)
		if not retryable or attempt >= max_retries:
			break
		await get_tree().create_timer(retry_backoff_base * pow(2, attempt)).timeout

	var msg: Variant = (last_res.error as Dictionary).get("message", last_res.error) if last_res.error is Dictionary else last_res.error
	return Result.err(msg)


func _acquire_request() -> HTTPRequest:
	if not _free_pool.is_empty():
		return _free_pool.pop_back()
	var hr := HTTPRequest.new()
	# 必须入树，HTTPRequest 才能完成请求。
	NodeUtils.mount_required(hr, self, "HTTPRequest_%d" % get_child_count())
	return hr


func _release_request(hr: HTTPRequest) -> void:
	_free_pool.append(hr)
#endregion
