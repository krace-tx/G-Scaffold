class_name LevelManager
extends RefCounted

## 关卡与主题相册业务管理器。
## 负责关卡查询、相册展示状态快照计算、主线关卡推进与通关通知。

#region Signals
## 当玩家通关某一关卡时发射。[br]
## [param level_id]：通关的关卡编号（从 1 开始）。
signal level_completed(level_id: int)
#endregion


#region Level Properties & Queries
## 当前配置中生效的关卡总数
var total_levels: int:
	get:
		var cfg := _level_config
		return cfg.levels.size() if cfg != null else 0


## 全部主题相册列表
var themes: Array[LevelTheme]:
	get:
		var cfg := _level_config
		return cfg.themes if cfg != null else []


## 当前主题相册总数
var total_themes: int:
	get:
		return themes.size()


## 玩家当前应该进行的关卡实体（全通关后保留在最后一关）
var current_level: LevelItem:
	get:
		var current_id := Game.profile.current_level if (Game != null and Game.profile != null) else 1
		if total_levels > 0 and current_id > total_levels:
			current_id = total_levels
		var item := get_level(current_id)
		if item != null:
			return item

		var cfg := _level_config
		if cfg != null and not cfg.levels.is_empty():
			return cfg.levels.back()
		return LevelItem.new()


## 玩家当前正在收集的主题相册实体
var current_theme: LevelTheme:
	get:
		return get_progress().theme


## 玩家当前正在收集的主题相册序号
var current_theme_index: int:
	get:
		return get_progress().theme_index


## 根据关卡编号获取关卡配置数据，不存在返回 null
func get_level(level_id: int) -> LevelItem:
	var cfg := _level_config
	if cfg == null or level_id <= 0 or level_id > cfg.levels.size():
		return null
	return cfg.levels[level_id - 1]


## 根据主题序号获取相册数据，不存在返回 null
func get_theme(index: int) -> LevelTheme:
	var cfg := _level_config
	if cfg == null or index < 0 or index >= cfg.themes.size():
		return null
	return cfg.themes[index]


## 玩家是否已经通关全部主线关卡
func is_all_cleared() -> bool:
	if Game == null or Game.profile == null or total_levels == 0:
		return false
	return Game.profile.current_level > total_levels
#endregion


#region Progress Calculation (Domain Core)
## 计算当前玩家进度对应的主题相册状态快照
func get_progress() -> ThemeProgress:
	var current_id := Game.profile.current_level if (Game != null and Game.profile != null) else 1
	return get_progress_at_level(current_id)


## 计算指定关卡进度达成时的主题相册状态快照
func get_progress_at_level(target_level_id: int) -> ThemeProgress:
	var p := ThemeProgress.new()
	var cfg := _level_config
	if cfg == null or cfg.themes.is_empty():
		p.theme = LevelTheme.new()
		return p

	var all_cleared := (total_levels > 0 and target_level_id > total_levels)
	p.is_all_cleared = all_cleared

	# 全通关状态：固定为最后一章、全满碎片、关卡停留在最后一关
	if all_cleared:
		var last_idx := cfg.themes.size() - 1
		p.theme = cfg.themes[last_idx]
		p.theme_index = last_idx
		p.theme_title = p.theme.title
		p.total_pieces = p.theme.static_pieces.size()
		p.unlocked_pieces = p.total_pieces
		p.display_level_id = total_levels
		p.is_last_piece = true
		p.is_last_theme = true
		return p

	# 遍历各主题切片区间，定位当前关卡所处主题与已解锁数
	var accumulated := 0
	var completed_levels := maxi(target_level_id - 1, 0)
	for t_idx in range(cfg.themes.size()):
		var theme := cfg.themes[t_idx]
		var t_pieces := theme.static_pieces.size()
		var is_last_t := (t_idx == cfg.themes.size() - 1)

		if is_last_t or completed_levels < accumulated + t_pieces:
			p.theme = theme
			p.theme_index = t_idx
			p.theme_title = theme.title
			p.total_pieces = t_pieces
			p.unlocked_pieces = mini(completed_levels - accumulated, t_pieces)
			p.display_level_id = clampi(target_level_id, 1, total_levels) if total_levels > 0 else 1
			p.is_last_piece = (p.unlocked_pieces >= t_pieces and t_pieces > 0)
			p.is_last_theme = is_last_t
			return p

		accumulated += t_pieces

	return p
#endregion


#region Settlement
## 通关指定关卡，推进档案进度，并返回结算前后快照及切章指令
func pass_level(level_id: int) -> Dictionary:
	var before_progress := get_progress_at_level(level_id)
	# 刚完成此关：当前关卡对应的碎片解锁
	if level_id > 0:
		before_progress.unlocked_pieces = mini(before_progress.unlocked_pieces + 1, before_progress.total_pieces)
		before_progress.is_last_piece = (before_progress.unlocked_pieces >= before_progress.total_pieces)

	# 推进关卡主线档案
	if Game != null and Game.profile != null and level_id >= Game.profile.current_level:
		Game.profile.current_level = level_id + 1
		Game.profile.current_level_viewed = false

	var after_progress := get_progress()
	level_completed.emit(level_id)

	return {
		"before": before_progress,
		"after": after_progress,
		"should_switch_theme": before_progress.is_last_piece and not before_progress.is_last_theme
	}
#endregion


#region Internal
var _level_config: LevelConfig:
	get:
		return Game.config.level_config if (Game != null and Game.config != null) else null
#endregion
