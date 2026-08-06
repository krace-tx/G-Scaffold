class_name ImageCacheService
extends RefCounted

## 远程图片缓存服务。
##
## [b]为什么这么设计[/b][br]
## 统一管理远程图片的「内存缓存 + 磁盘缓存 + 下载」，底层复用 [PersistService]：
## - 内存缓存直接使用 PersistService 的内存池（多处引用同一张 Texture2D，避免重复解码/占用）。
## - 磁盘缓存落在本服务专属目录，文件名取 URL 的 md5，扩展名取 URL 后缀（默认 jpg）。
## - 下载走 [NetworkService]，可选携带 md5 校验（失败自动删除损坏文件）。
## - 也支持本地路径（[code]user://[/code] / [code]res://[/code]）：此时无需下载，直接校验 md5 并加载。
## - 也支持传入自定义 [PersistItem]：自行指定内存 key、磁盘路径与拉取地址。
##
## md5 为可选参数：传入后会对磁盘文件做完整性校验（[method FileAccess.get_md5]），
## 内存命中同样以其对应磁盘文件的 md5 作为校验依据。
##
## [b]API 使用样例[/b][br]
## [codeblock]
## # 读缓存（无则返回 null）
## var tex := App.image_cache.get_cached_image(url, md5)
## if tex == null:
##     # 缓存缺失时再下载
##     tex = await App.image_cache.download_image(url, md5, true)
##
## # 自定义 PersistItem（指定 key / 磁盘路径 / 拉取地址）
## var item := PersistItem.new("MyImage", "user://custom/a.png", "", url)
## tex = App.image_cache.get_cached_image_item(item, md5)
## if tex == null:
##     tex = await App.image_cache.download_image_item(item, md5, true)
## [/codeblock]

#region Constants & Enums
## 图片磁盘缓存目录
const IMAGE_CACHE_DIR := "user://framework/asset_cache_service/image/"
#endregion

#region Public API
## 读取图片缓存：内存命中直接返回；否则读磁盘（可选回灌内存），都没有则返回 null。[br]
## [param url] 远程图片地址或本地路径（[code]http(s)://[/code] / [code]user://[/code] / [code]res://[/code]）;[br]
## [param md5] 期望的文件 md5,为空则跳过校验;不为空且内存/磁盘数据不匹配时返回 null;[br]
## [param cache_in_memory] 磁盘命中时是否回灌内存缓存(默认 true)。[br]
## 返回命中的 [Texture2D]，未命中或校验失败返回 [code]null[/code]。
func get_cached_image(url: String, md5: String = "", cache_in_memory: bool = true) -> Texture2D:
	if url.is_empty():
		return null
	return get_cached_image_item(_build_item(url), md5, cache_in_memory)


## 使用自定义 [PersistItem] 读取图片缓存。[br]
## [param item] 自定义持久化项（[member PersistItem.key] 作内存 key，[member PersistItem.path] 作磁盘路径）;[br]
## [param md5] 期望的文件 md5,为空则跳过校验;不为空且内存/磁盘数据不匹配时返回 null;[br]
## [param cache_in_memory] 磁盘命中时是否回灌内存缓存(默认 true)。[br]
## 返回命中的 [Texture2D]，未命中或校验失败返回 [code]null[/code]。
func get_cached_image_item(item: PersistItem, md5: String = "", cache_in_memory: bool = true) -> Texture2D:
	if item == null or item.path.is_empty() or not App.persist:
		return null

	# 1. 内存缓存命中（以对应磁盘文件的 md5 作为校验依据）
	var mem: Variant = App.persist.read(item, PersistService.ReadMode.MEMORY_ONLY)
	if mem is Texture2D:
		return mem

	# 2. 磁盘缓存命中
	if not FileAccess.file_exists(item.path):
		return null
	if not _md5_matches(item.path, md5):
		return null

	if cache_in_memory:
		# 读磁盘并回灌内存缓存（交给 PersistService）
		var tex: Variant = App.persist.read(item, PersistService.ReadMode.MEMORY_THEN_DISK)
		return tex if tex is Texture2D else null
	# 仅读磁盘,不写内存
	return PersistService.load_texture_from_path(item.path)


## 获取图片：远程 URL 走 [NetworkService] 下载，本地路径（[code]user://[/code] / [code]res://[/code]）直接读取。[br]
## 结果符合 md5（或未传 md5）时可选写入内存，并返回 [Texture2D]。[br]
## [param url] 远程图片地址或本地路径（[code]http(s)://[/code] / [code]user://[/code] / [code]res://[/code]）;[br]
## [param md5] 期望的文件 md5,为空则不校验;不为空且结果不匹配时返回 null;[br]
## [param cache_in_memory] 是否写入内存缓存(默认 false)。[br]
## 该方法为异步。返回得到的 [Texture2D]，失败返回 [code]null[/code]。
func download_image(url: String, md5: String = "", cache_in_memory: bool = false) -> Texture2D:
	if url.is_empty():
		App.log.warn("ImageCacheService", "download_image skipped: empty url")
		return null
	return await download_image_item(_build_item(url), md5, cache_in_memory)


## 使用自定义 [PersistItem] 获取图片。[br]
## 有 [member PersistItem.pull_url] 时按远程下载到 [member PersistItem.path]；[br]
## 否则若 [member PersistItem.path] 为本地路径则直接读取。[br]
## [param item] 自定义持久化项;[br]
## [param md5] 期望的文件 md5,为空则不校验;不为空且结果不匹配时返回 null;[br]
## [param cache_in_memory] 是否写入内存缓存(默认 false)。[br]
## 该方法为异步。返回得到的 [Texture2D]，失败返回 [code]null[/code]。
func download_image_item(item: PersistItem, md5: String = "", cache_in_memory: bool = false) -> Texture2D:
	if item == null or item.path.is_empty():
		App.log.warn("ImageCacheService", "download_image_item skipped: invalid item")
		return null

	var source := item.pull_url if not item.pull_url.is_empty() else item.path

	# 本地路径（user:// / res://）：无需下载，直接校验 md5 并加载
	if item.pull_url.is_empty() and _is_local_path(item.path):
		if not _md5_matches(item.path, md5):
			App.log.warn("ImageCacheService", "download_image_item md5 mismatch or missing file: %s" % source)
			return null
		var local_texture := PersistService.load_texture_from_path(item.path)
		if local_texture == null:
			App.log.warn("ImageCacheService", "download_image_item decode failed: %s" % source)
			return null
		if cache_in_memory and App.persist:
			App.persist.write(item, PersistService.WriteMode.MEMORY_ONLY, local_texture)
		App.log.info("ImageCacheService", "download_image_item local success: %s" % source)
		return local_texture

	# 远程 URL：走 NetworkService 下载到 item.path
	if not _is_remote_url(source):
		App.log.warn("ImageCacheService", "download_image_item skipped: invalid url: %s" % source)
		return null
	if not App.net:
		App.log.error("ImageCacheService", "download_image_item failed: NetworkService is not initialized")
		return null

	var cache_dir := item.path.get_base_dir()
	if cache_dir.is_empty():
		cache_dir = IMAGE_CACHE_DIR
	var result: Result = FileUtils.ensure_dir_exists(cache_dir)
	if result.is_err():
		App.log.error("ImageCacheService", "cache directory ensure failed: %s" % result.error)
		return null

	# 下载到磁盘：带 md5 时使用带校验的下载（不匹配会自动删除文件）
	var dl: Result
	if md5.is_empty():
		dl = await App.net.download_file(source, item.path)
	else:
		dl = await App.net.download_file_with_md5(source, item.path, md5)
	if dl.is_err():
		App.log.warn("ImageCacheService", "download_image_item failed: %s (%s)" % [dl.error, source])
		return null

	var texture := PersistService.load_texture_from_path(item.path)
	if texture == null:
		App.log.warn("ImageCacheService", "download_image_item decode failed: %s" % source)
		return null

	# 磁盘已由下载写入,这里仅按需把纹理放入 PersistService 内存缓存
	if cache_in_memory and App.persist:
		App.persist.write(item, PersistService.WriteMode.MEMORY_ONLY, texture)

	App.log.info("ImageCacheService", "download_image_item success: %s" % source)
	return texture


## 远程图片对应的本地磁盘缓存路径
func cache_path(url: String) -> String:
	return "%s%s.%s" % [IMAGE_CACHE_DIR, url.md5_text(), _url_extension(url)]
#endregion

#region Internal
## 为指定 URL/路径构造 PersistItem：key 取其 md5。[br]
## - 远程 URL：磁盘路径为本地缓存路径(user://)，拉取地址为该 URL;[br]
## - 本地路径(user:// / res://)：磁盘路径即该路径本身，无拉取地址。
func _build_item(url: String) -> PersistItem:
	var is_local := _is_local_path(url)
	var disk_path := url if is_local else cache_path(url)   ## 本地路径直接复用，远程使用缓存路径
	var pull_url := "" if is_local else url                 ## 本地路径无需拉取
	return PersistItem.new(
		"ImageCacheService-%s" % url.md5_text(),   ## 资源 ID（内存缓存 key）
		disk_path,                                  ## 磁盘路径
		"",                                         ## 本地兜底资源,无需
		pull_url, "GET",                            ## 拉取地址(下载改由 NetworkService 直连以支持 md5 校验)
		"", "POST",                                 ## 推送地址,图片缓存不推送
		{}                                          ## 图片管线无需字段映射
	)


## 校验磁盘文件 md5：md5 为空视为通过；文件不存在或不匹配视为失败
func _md5_matches(path: String, md5: String) -> bool:
	if md5.is_empty():
		return true
	if not FileAccess.file_exists(path):
		return false
	return FileAccess.get_md5(path) == md5


## 取 URL 的文件扩展名（剥离查询串），不在支持列表时默认 png
func _url_extension(url: String) -> String:
	var clean := url
	var query_index := clean.find("?")
	if query_index != -1:
		clean = clean.substr(0, query_index)
	var ext := clean.get_extension().to_lower()
	if ext in PersistService.TEXTURE_EXTENSIONS:
		return ext
	return "png"


func _is_remote_url(url: String) -> bool:
	return url.begins_with("http://") or url.begins_with("https://")


## 是否为本地路径（Godot 虚拟目录）
func _is_local_path(url: String) -> bool:
	return url.begins_with("user://") or url.begins_with("res://")
#endregion
