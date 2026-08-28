class_name AssetManager
extends RefCounted

## 游戏素材资产管理器（轻量级通用资产中枢）。
## 纯粹负责素材项的注册登记、分级下载调度、本地磁盘缓存与内存资源池，不耦合具体业务配置。

#region State
## 已注册的素材项元数据映射表 (key: String -> AssetEntry)
var _registry: Dictionary = {}

## 内存中已解码完成的资源对象池 (key: String -> Resource)
var _cache: Dictionary = {}
#endregion


#region Registration
## 注册单条素材描述项
func register(entry: AssetEntry) -> void:
	if entry != null and not entry.key.is_empty():
		_registry[entry.key] = entry


## 批量注册素材描述项
func register_all(entries: Array[AssetEntry]) -> void:
	for entry in entries:
		register(entry)
	App.log.debug("AssetManager", "Registered %d asset entries (total registry size: %d)" % [entries.size(), _registry.size()])


## 检查指定 key 的素材是否已注册
func has(key: String) -> bool:
	return _registry.has(key)
#endregion


#region Preload
## 异步批量下载所有标记为 REQUIRED 的启动必下素材
func preload_required_async(on_progress: Callable = Callable()) -> Result:
	var required_keys: Array[String] = []
	for key: String in _registry:
		var entry: AssetEntry = _registry[key]
		if entry.is_required and not is_cached(key):
			required_keys.append(key)

	var total := required_keys.size()
	if total == 0:
		if on_progress.is_valid():
			on_progress.call(1.0)
		return Result.ok()

	var completed := 0
	if on_progress.is_valid():
		on_progress.call(0.0)

	App.log.info("AssetManager", "Preloading %d required assets..." % total)
	for key in required_keys:
		var res := await download_async(key)
		if res.is_err():
			App.log.warn("AssetManager", "Preload asset failed for '%s': %s" % [key, res.error])
		completed += 1
		if on_progress.is_valid():
			on_progress.call(float(completed) / float(total))

	App.log.info("AssetManager", "Preload completed (%d required assets)" % total)
	return Result.ok()
#endregion


#region Consumption & Loading
## 核心异步加载方法：内存 ➔ 磁盘 ➔ 远端网络 ➔ 解码 Resource（如 Texture2D / AudioStream）
func load_async(key: String) -> Result:
	# 1. 命中内存池
	if _cache.has(key):
		App.log.debug("AssetManager", "Memory cache hit: [%s]" % key)
		return Result.ok(_cache[key])

	var entry: AssetEntry = _registry.get(key)
	if entry == null:
		App.log.warn("AssetManager", "Load failed: Asset '%s' not registered" % key)
		return Result.err("Asset '%s' not registered" % key)

	# 2. 保证本地磁盘文件就绪
	var dl_res := await download_async(key)
	if dl_res.is_err():
		App.log.error("AssetManager", "Download step failed for '%s': %s" % [key, dl_res.error])
		return dl_res

	# 3. 从磁盘解码为对应引擎 Resource 对象
	var local_path := get_disk_path(key)
	var res := _decode_from_disk(local_path, entry.type)
	if res.is_ok():
		_cache[key] = res.value
		App.log.debug("AssetManager", "Decoded and cached asset [%s] from disk: %s" % [key, local_path])
	else:
		App.log.error("AssetManager", "Failed to decode asset [%s]: %s" % [key, res.error])
	return res


## 异步加载图像缩略图：按目标尺寸等比下采样压缩，大幅节约 VRAM / 内存
func load_thumbnail_async(key: String, max_width: int = 340, max_height: int = 480) -> Result:
	var thumb_key := "%s_thumb_%dx%d" % [key, max_width, max_height]
	if _cache.has(thumb_key):
		App.log.debug("AssetManager", "Thumbnail cache hit: [%s]" % thumb_key)
		return Result.ok(_cache[thumb_key])

	var entry: AssetEntry = _registry.get(key)
	if entry == null:
		return Result.err("Asset '%s' not registered" % key)

	# 确保本地磁盘文件就绪
	var dl_res := await download_async(key)
	if dl_res.is_err():
		return dl_res

	var local_path := get_disk_path(key)
	var ext := local_path.get_extension().to_lower()
	if entry.type == AssetEntry.Type.IMAGE or ext in ["png", "jpg", "jpeg", "webp"]:
		var img := Image.load_from_file(local_path)
		if img == null or img.is_empty():
			return Result.err("Failed to decode image from: %s" % local_path)

		var orig_size := img.get_size()
		var new_w := orig_size.x
		var new_h := orig_size.y
		if orig_size.x > max_width or orig_size.y > max_height:
			var scale: float = minf(float(max_width) / float(orig_size.x), float(max_height) / float(orig_size.y))
			new_w = maxi(int(orig_size.x * scale), 1)
			new_h = maxi(int(orig_size.y * scale), 1)
			img.resize(new_w, new_h, Image.INTERPOLATE_BILINEAR)

		var tex := ImageTexture.create_from_image(img)
		_cache[thumb_key] = tex
		App.log.debug("AssetManager", "Created thumbnail [%s]: (orig: %dx%d -> downscaled: %dx%d, cached)" % [
			thumb_key, orig_size.x, orig_size.y, new_w, new_h
		])
		return Result.ok(tex)

	return await load_async(key)
#endregion


#region Disk & Cache
## 获取素材在本地磁盘上的绝对存储路径
func get_disk_path(key: String) -> String:
	var entry: AssetEntry = _registry.get(key)
	if entry == null or entry.url.is_empty():
		return ""

	# 1. 优先使用配置中的自定义 filename，其次从 URL 中解析文件名，最后兜底使用 key 或 MD5
	var file_name: String = ""
	if not entry.filename.is_empty():
		file_name = entry.filename
	else:
		file_name = entry.url.get_file().get_basename()
	
	if file_name.is_empty():
		file_name = entry.key if not entry.key.is_empty() else (entry.md5 if not entry.md5.is_empty() else entry.url.md5_text())

	var ext: String = entry.url.get_extension()
	if ext.is_empty():
		ext = "png" if entry.type == AssetEntry.Type.IMAGE else "bin"

	# 2. 拼接目录结构：DIR_ASSETS + [folder/] + filename.ext
	var base_dir := StorageCatalog.DIR_ASSETS
	if not entry.folder.is_empty():
		base_dir = base_dir.path_join(entry.folder) + "/"

	return base_dir + file_name + "." + ext


## 检查指定素材是否已在本地磁盘且 MD5 校验一致
func is_cached(key: String) -> bool:
	var entry: AssetEntry = _registry.get(key)
	if entry == null:
		return false

	var disk_path := get_disk_path(key)
	if not FileUtils.file_exists(disk_path):
		return false

	if not entry.md5.is_empty():
		var actual_md5 := FileAccess.get_md5(disk_path)
		if actual_md5.nocasecmp_to(entry.md5) != 0:
			FileUtils.remove_file(disk_path)
			return false

	return true


## 异步下载指定素材到本地磁盘
func download_async(key: String) -> Result:
	var entry: AssetEntry = _registry.get(key)
	if entry == null:
		return Result.err("Asset '%s' not registered" % key)

	if is_cached(key):
		return Result.ok(get_disk_path(key))

	if App.net == null:
		App.log.error("AssetManager", "Download failed: App.net is null")
		return Result.err("App.net is null")

	var disk_path := get_disk_path(key)
	FileUtils.ensure_dir_exists(disk_path.get_base_dir() + "/")

	App.log.debug("AssetManager", "Downloading asset [%s] from %s -> %s" % [key, entry.url, disk_path])
	var res: Result
	if not entry.md5.is_empty():
		res = await App.net.download_file_with_md5(entry.url, disk_path, entry.md5)
	else:
		res = await App.net.download_file(entry.url, disk_path)

	if res.is_err():
		App.log.error("AssetManager", "Download network failed for '%s': %s" % [key, res.error])
		return res

	# 落盘后校验
	if not entry.md5.is_empty():
		var disk_md5 := FileAccess.get_md5(disk_path)
		if disk_md5.nocasecmp_to(entry.md5) != 0:
			FileUtils.remove_file(disk_path)
			App.log.error("AssetManager", "MD5 mismatch for '%s' (expected: %s, got: %s)" % [key, entry.md5, disk_md5])
			return Result.err("MD5 mismatch for '%s'" % key)

	App.log.info("AssetManager", "Downloaded asset [%s] to disk successfully" % key)
	return Result.ok(disk_path)


## 释放指定素材的内存引用
func release(key: String) -> void:
	if _cache.has(key):
		_cache.erase(key)
		App.log.debug("AssetManager", "Released asset [%s] from memory" % key)


## 释放指定素材的缩略图内存缓存
func release_thumbnail(key: String, max_width: int = 340, max_height: int = 480) -> void:
	var thumb_key := "%s_thumb_%dx%d" % [key, max_width, max_height]
	if _cache.has(thumb_key):
		_cache.erase(thumb_key)
		App.log.debug("AssetManager", "Released thumbnail [%s] from memory" % thumb_key)


## 清空所有已缓存的缩略图纹理（释放 VRAM / 显存）
func clear_thumbnails() -> int:
	var thumb_keys: Array[String] = []
	for k: String in _cache:
		if "_thumb_" in k:
			thumb_keys.append(k)

	for k in thumb_keys:
		_cache.erase(k)

	if not thumb_keys.is_empty():
		App.log.debug("AssetManager", "Cleared %d thumbnail textures from memory. Remaining cache entries: %d" % [
			thumb_keys.size(), _cache.size()
		])
	return thumb_keys.size()


## 清空全部内存资源池
func clear() -> void:
	var count := _cache.size()
	_cache.clear()
	if count > 0:
		App.log.debug("AssetManager", "Cleared entire asset memory pool (%d entries)" % count)
#endregion


#region Internal
static func _decode_from_disk(local_path: String, type: AssetEntry.Type) -> Result:
	var ext := local_path.get_extension().to_lower()

	# 1. 图像类解码为 Texture2D
	if type == AssetEntry.Type.IMAGE or ext in ["png", "jpg", "jpeg", "webp"]:
		var img := Image.load_from_file(local_path)
		if img == null or img.is_empty():
			return Result.err("Failed to decode image from: %s" % local_path)
		return Result.ok(ImageTexture.create_from_image(img))

	# 2. 音频类解码为 AudioStream
	if type == AssetEntry.Type.AUDIO or ext in ["mp3", "ogg"]:
		if ext == "mp3":
			var read_res := FileUtils.read_bytes(local_path)
			if read_res.is_err():
				return read_res
			var stream := AudioStreamMP3.new()
			stream.data = read_res.value
			return Result.ok(stream)
		elif ext == "ogg":
			var stream := AudioStreamOggVorbis.load_from_file(local_path)
			if stream == null:
				return Result.err("Failed to read ogg: %s" % local_path)
			return Result.ok(stream)

	# 3. 通用二进制使用 FileUtils 安全读取
	return FileUtils.read_bytes(local_path)
#endregion
