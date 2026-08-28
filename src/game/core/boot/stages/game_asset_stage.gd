class_name GameAssetStage
extends BootStage

## 初始游戏素材资产装配与预下载阶段。
## 负责将游戏配置中的关卡底图、相册封面与拼图碎片注入 [Game.asset]，并批量预载启动必下素材。


func id() -> String:
	return "GameAsset"


func weight() -> float:
	return 7.0


func run(on_progress: Callable = Callable()) -> Result:
	if Game == null or Game.asset == null:
		return Result.ok()

	# 1. 业务装配：从全局配置与进度中提取所有素材项并向 AssetManager 注册
	_register_business_assets()

	# 2. 执行所有标记为 REQUIRED 必须素材的阻塞式下载（实时上报完成比例）
	await Game.asset.preload_required_async(on_progress)
	info("Required assets preloaded successfully")
	return Result.ok()


#region Business Asset Injection
func _register_business_assets() -> void:
	if Game.config == null or Game.config.level_config == null:
		return

	var level_cfg := Game.config.level_config
	var current_level_id := Game.profile.current_level if Game.profile != null else 1
	var current_theme_index := Game.level.current_theme.index if (Game != null and Game.level != null) else 0
	var next_theme_index := current_theme_index + 1

	# 1. 关卡底图（当前进行的主线关卡标记为 REQUIRED 启动必下）
	for item in level_cfg.levels:
		var entry := AssetEntry.new()
		entry.key = AssetCatalog.level_texture(item.level_id)
		entry.type = AssetEntry.Type.IMAGE
		entry.url = item.texture_url
		entry.md5 = item.texture_md5
		entry.folder = AssetCatalog.level_folder()
		entry.filename = "level_%d" % item.level_id
		entry.is_required = (item.level_id == current_level_id)
		Game.asset.register(entry)

	# 2. 主题相册封面与拼图碎片（仅当前章与下一章标记为 REQUIRED 启动必下）
	for theme in level_cfg.themes:
		var is_theme_required := (theme.index == current_theme_index or theme.index == next_theme_index)

		# 2.1 主题封面
		var cover_entry := AssetEntry.new()
		cover_entry.key = AssetCatalog.theme_cover(theme.index)
		cover_entry.type = AssetEntry.Type.IMAGE
		cover_entry.url = theme.cover_url
		cover_entry.md5 = theme.cover_md5
		cover_entry.folder = AssetCatalog.theme_folder(theme.index)
		cover_entry.filename = "cover"
		cover_entry.is_required = is_theme_required
		Game.asset.register(cover_entry)

		# 2.2 动态动画碎片
		for i in theme.anim_pieces.size():
			var piece: LevelPiece = theme.anim_pieces[i]
			var piece_entry := AssetEntry.new()
			piece_entry.key = AssetCatalog.theme_anim_piece(theme.index, i)
			piece_entry.type = AssetEntry.Type.IMAGE
			piece_entry.url = piece.texture_url
			piece_entry.md5 = piece.texture_md5
			piece_entry.folder = AssetCatalog.theme_anim_folder(theme.index)
			piece_entry.filename = "anim_piece_%d" % i
			piece_entry.is_required = is_theme_required
			Game.asset.register(piece_entry)

		# 2.3 静态拼图碎片
		for i in theme.static_pieces.size():
			var piece: LevelPiece = theme.static_pieces[i]
			var piece_entry := AssetEntry.new()
			piece_entry.key = AssetCatalog.theme_static_piece(theme.index, i)
			piece_entry.type = AssetEntry.Type.IMAGE
			piece_entry.url = piece.texture_url
			piece_entry.md5 = piece.texture_md5
			piece_entry.folder = AssetCatalog.theme_static_folder(theme.index)
			piece_entry.filename = "static_piece_%d" % i
			piece_entry.is_required = is_theme_required
			Game.asset.register(piece_entry)
#endregion
