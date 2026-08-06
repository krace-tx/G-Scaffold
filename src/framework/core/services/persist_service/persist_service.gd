class_name PersistService
extends RefCounted

## 数据持久化服务，支持内存缓存、磁盘持久化、服务器上传下载。


#region Constants & Enums
enum ReadMode {
	MEMORY_ONLY,                  ## 只读内存
	MEMORY_THEN_DISK,             ## 先读内存，不存在就读磁盘，并在内存中缓存磁盘结果
	MEMORY_THEN_DISK_THEN_HTTP,   ## 先读内存，不存在再读磁盘，还不存在就发起http调用并将结果同时写入磁盘并缓存内存
	HTTP_ONLY                     ## 直接从http获取数据，并同步到内存和磁盘
}

enum WriteMode {
	MEMORY_ONLY,                  ## 只写内存
	MEMORY_AND_DISK,              ## 先写内存，并同时把新数据写入磁盘
	MEMORY_AND_DISK_AND_HTTP,     ## 先写内存，把新数据写入磁盘，并通过http接口上传服务器
	HTTP_FIRST                    ## 先通过http上传数据，成功后才去写入内存和磁盘
}

## 走图片管线（Texture2D 读写）的磁盘文件扩展名（小写，不含点）
const TEXTURE_EXTENSIONS: Array[String] = ["png", "jpg", "jpeg", "webp"]
#endregion

#region Exports & State
var _cache: Dictionary = {}       # key -> Variant (Resource or Texture2D)
#endregion

#region Public API
## 从指定的数据项中读取数据（仅内存 / 磁盘，不涉及网络，故为同步方法）。[br]
## [param item] 数据项配置;[br]
## [param mode] 读取模式，仅支持 [enum ReadMode] 的 [code]MEMORY_ONLY[/code] 与 [code]MEMORY_THEN_DISK[/code]。[br]
## 若需要 HTTP 回源，请改用 [method read_with_http]。[br]
## 返回 [Variant]：读取到的数据（Resource 或 Texture2D），失败或不存在时返回 [code]null[/code]。
func read(item: PersistItem, mode: ReadMode) -> Variant:
	if item == null or item.key.is_empty():
		App.log.error("PersistService", "Read failed: item or key is empty")
		return null
	match mode:
		ReadMode.MEMORY_ONLY:
			return _read_memory(item)
		ReadMode.MEMORY_THEN_DISK:
			var data: Variant = _read_memory(item)
			if data != null:
				return data
			data = _read_disk(item)
			if data != null:
				_write_memory(item, data)
				return data
			return null
	App.log.error("PersistService", "read() only supports MEMORY_ONLY / MEMORY_THEN_DISK; use read_with_http() for HTTP modes")
	return null

## 从指定的数据项中读取数据，支持在内存/磁盘缺失时通过 HTTP 回源（异步方法）。[br]
## [param item] 数据项配置;[br]
## [param mode] 读取模式，仅支持 [enum ReadMode] 的 [code]MEMORY_THEN_DISK_THEN_HTTP[/code] 与 [code]HTTP_ONLY[/code]。[br]
## 若仅需内存/磁盘读取，请改用 [method read]。[br]
## 该方法为异步。返回 [Variant]：读取到的数据（Resource 或 Texture2D），失败或不存在时返回 [code]null[/code]。
func read_with_http(item: PersistItem, mode: ReadMode, pull_body: Dictionary = {}) -> Variant:
	if item == null or item.key.is_empty():
		App.log.error("PersistService", "Read failed: item or key is empty")
		return null
	match mode:
		ReadMode.MEMORY_THEN_DISK_THEN_HTTP:
			var data: Variant = _read_memory(item)
			if data != null:
				return data
			data = _read_disk(item)
			if data != null:
				_write_memory(item, data)
				return data
			data = await _read_http(item, pull_body)
			if data != null:
				_write_memory(item, data)
				_write_disk(item, data)
				return data
			return null
		ReadMode.HTTP_ONLY:
			var data: Variant = await _read_http(item, pull_body)
			if data != null:
				_write_memory(item, data)
				_write_disk(item, data)
				return data
			return null
	App.log.error("PersistService", "read_with_http() only supports MEMORY_THEN_DISK_THEN_HTTP / HTTP_ONLY; use read() for non-HTTP modes")
	return null

## 将数据写入指定的数据项（仅内存 / 磁盘，不涉及网络，故为同步方法）。[br]
## [param item] 数据项配置;[br]
## [param mode] 写入模式，仅支持 [enum WriteMode] 的 [code]MEMORY_ONLY[/code] 与 [code]MEMORY_AND_DISK[/code];[br]
## [param data] 待写入的数据（Resource 或 Texture2D）。[br]
## 若需要上传服务端，请改用 [method write_with_http]。[br]
## 返回 [Result]：成功时 [member Result.value] 为空，失败时返回详细错误。
func write(item: PersistItem, mode: WriteMode, data: Variant) -> Result:
	if item == null or item.key.is_empty():
		return Result.err("Write failed: item or key is empty")
	if data == null:
		return Result.err("Write failed: data is null")
	match mode:
		WriteMode.MEMORY_ONLY:
			_write_memory(item, data)
			return Result.ok()
		WriteMode.MEMORY_AND_DISK:
			_write_memory(item, data)
			var disk_res := _write_disk(item, data)
			if disk_res.is_err():
				return disk_res
			return Result.ok()
	return Result.err("write() only supports MEMORY_ONLY / MEMORY_AND_DISK; use write_with_http() for HTTP modes")

## 将数据写入指定的数据项，并通过 HTTP 上传服务端（异步方法）。[br]
## [param item] 数据项配置;[br]
## [param mode] 写入模式，仅支持 [enum WriteMode] 的 [code]MEMORY_AND_DISK_AND_HTTP[/code] 与 [code]HTTP_FIRST[/code];[br]
## [param data] 待写入的数据（Resource 或 Texture2D）。[br]
## 若仅需内存/磁盘写入，请改用 [method write]。[br]
## 该方法为异步。返回 [Result]：成功时 [member Result.value] 为上传响应值，失败时返回详细错误。
func write_with_http(item: PersistItem, mode: WriteMode, data: Variant) -> Result:
	if item == null or item.key.is_empty():
		return Result.err("Write failed: item or key is empty")
	if data == null:
		return Result.err("Write failed: data is null")
	match mode:
		WriteMode.MEMORY_AND_DISK_AND_HTTP:
			_write_memory(item, data)
			var disk_res := _write_disk(item, data)
			if disk_res.is_err():
				return disk_res
			var http_res: Result = await _write_http(item, data)
			if http_res.is_err():
				return http_res
			return Result.ok(http_res.value)
		WriteMode.HTTP_FIRST:
			var http_res: Result = await _write_http(item, data)
			if http_res.is_err():
				return http_res
			_write_memory(item, data)
			var disk_res := _write_disk(item, data)
			if disk_res.is_err():
				return disk_res
			return Result.ok(http_res.value)
	return Result.err("write_with_http() only supports MEMORY_AND_DISK_AND_HTTP / HTTP_FIRST; use write() for non-HTTP modes")
#endregion

#region Internal
func _read_memory(item: PersistItem) -> Variant:
	return _cache.get(item.key, null)

func _write_memory(item: PersistItem, data: Variant) -> void:
	_cache[item.key] = data

func _read_disk(item: PersistItem) -> Variant:
	var disk_path: String = item.path		
	if disk_path.is_empty() or (not FileAccess.file_exists(disk_path)):
		# 如果path(user)目录下不存在，使用backup_path(res)兜底
		disk_path = item.backup_path
	if disk_path.is_empty() or (not FileAccess.file_exists(disk_path)):
		return null
		
	if _is_texture_pipeline(item):
		return load_texture_from_path(disk_path)
	else:
		if disk_path.ends_with(".tres"):
			var res := ResourceLoader.load(disk_path)
			if res:
				return res
		elif disk_path.ends_with(".json"):
			var json_res := FileUtils.read_json(disk_path)
			if json_res.is_ok() and json_res.value is Dictionary:
				var res := ResourceJsonUtil.dict_to_resource(json_res.value, item.script_path_dict)
				if res:
					return res
	return null

func _write_disk(item: PersistItem, data: Variant) -> Result:
	if item.path.is_empty():
		return Result.err("Disk write failed: path is empty")
	var dir_res := FileUtils.ensure_dir_exists(item.path.get_base_dir())
	if dir_res.is_err():
		return Result.err("Disk write failed: failed to create directory: %s" % dir_res.error)
	if _is_texture_pipeline(item):
		var texture := data as Texture2D
		if not texture:
			return Result.err("Disk write failed: data is not a Texture2D")
		var img := texture.get_image()
		if not img or img.is_empty():
			return Result.err("Disk write failed: failed to get image from texture")
		var ext := item.path.get_extension().to_lower()
		var err := _save_image_to_path(img, item.path, ext)
		if err != OK:
			return Result.err("Disk write failed: save %s failed (err=%d)" % [ext, err])
	else:
		var resource := data as Resource
		if not resource:
			return Result.err("Disk write failed: data is not a Resource")
		var err := ResourceSaver.save(resource, item.path)
		if err != OK:
			return Result.err("Disk write failed: ResourceSaver.save failed (err=%d)" % err)
	return Result.ok()

func _read_http(item: PersistItem, pull_body: Dictionary = {}) -> Variant:
	if item.pull_url.is_empty():
		App.log.warn("PersistService", "HTTP read skipped: pull_url is empty")
		return null
	if not App.net:
		App.log.error("PersistService", "HTTP read failed: NetworkService is not initialized")
		return null
	if _is_texture_pipeline(item):
		var dl_res: Result = await App.net.download_file(item.pull_url, item.path)
		if dl_res.is_err():
			App.log.error("PersistService", "HTTP read failed: download_file failed: %s" % dl_res.error)
			return null
		return _read_disk(item)
	else:
		var res: Result
		print("item.pull_url", item.pull_url)
		if item.pull_method.to_upper() == "POST":
			res = await App.net.post_request(item.pull_url, pull_body)
		else:
			res = await App.net.get_request(item.pull_url, pull_body)
		if res.is_err():
			App.log.error("PersistService", "HTTP read failed: pull request failed: %s" % res.error)
			return null
		if res.value is Dictionary:
			if res.value.has("data"):
				return ResourceJsonUtil.dict_to_resource(res.value["data"], item.script_path_dict, "")
			else:
				return ResourceJsonUtil.dict_to_resource(res.value, item.script_path_dict, "")
		else:
			App.log.error("PersistService", "HTTP read failed: response is not a Dictionary")
			return null

func _write_http(item: PersistItem, data: Variant) -> Result:
	if item.push_url.is_empty():
		return Result.ok()
	if not App.net:
		return Result.err("HTTP write failed: NetworkService is not initialized")
	if _is_texture_pipeline(item):
		var texture := data as Texture2D
		if not texture:
			return Result.err("HTTP write failed: data is not a Texture2D")
		var img := texture.get_image()
		if not img or img.is_empty():
			return Result.err("HTTP write failed: failed to get image from texture")
		var ext := item.path.get_extension().to_lower()
		var bytes := _encode_image_to_buffer(img, ext)
		if bytes.is_empty():
			return Result.err("HTTP write failed: failed to encode texture to %s bytes" % ext)
		var filename: String = item.path.get_file()
		if filename.is_empty():
			filename = "image.%s" % (ext if not ext.is_empty() else "png")
		var upload_res: Result = await App.net.upload_file(
			item.push_url,
			"file",
			bytes,
			filename,
			_texture_mime_type(ext)
		)
		return upload_res
	else:
		var resource := data as Resource
		if not resource:
			return Result.err("HTTP write failed: data is not a Resource")
		var dict := ResourceJsonUtil.resource_to_dict(resource)
		if resource.get_script():
			dict["_script_path"] = resource.get_script().resource_path
		var res: Result
		if item.push_method.to_upper() == "GET":
			res = await App.net.get_request(item.push_url, dict)
		else:
			res = await App.net.post_request(item.push_url, dict)
		return res

func _is_texture_pipeline(item: PersistItem) -> bool:
	return item.path.get_extension().to_lower() in TEXTURE_EXTENSIONS

## 从路径加载纹理：res:// 走 ResourceLoader（导出可用），user:// 等走 Image 解码。
static func load_texture_from_path(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if path.begins_with("res://"):
		var res := ResourceLoader.load(path)
		return res as Texture2D if res is Texture2D else null
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		return null
	return ImageTexture.create_from_image(img)

## 按扩展名把图片写入磁盘，返回 Godot 错误码
func _save_image_to_path(img: Image, path: String, ext: String) -> int:
	match ext:
		"jpg", "jpeg":
			return img.save_jpg(path)
		"webp":
			return img.save_webp(path)
		_:
			return img.save_png(path)

## 按扩展名把图片编码为字节缓冲，用于上传
func _encode_image_to_buffer(img: Image, ext: String) -> PackedByteArray:
	match ext:
		"jpg", "jpeg":
			return img.save_jpg_to_buffer()
		"webp":
			return img.save_webp_to_buffer()
		_:
			return img.save_png_to_buffer()

## 按扩展名返回上传用的 MIME 类型
func _texture_mime_type(ext: String) -> String:
	match ext:
		"jpg", "jpeg":
			return "image/jpeg"
		"webp":
			return "image/webp"
		_:
			return "image/png"
#endregion
