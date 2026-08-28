class_name ThemeProgress
extends RefCounted

## 玩家当前所处的主题相册进度快照（强类型状态值对象）。
## 聚合了当前主题实体、切片解锁进度、大厅展示关卡号以及全通关/满章边界状态。

var theme: LevelTheme = null			## 当前关联的主题相册实体
var theme_index: int = 0				## 主题序号（0-indexed）
var theme_title: String = ""			## 主题标题名称
var unlocked_pieces: int = 0			## 当前主题下已解锁的切片数量（0 ~ total_pieces）
var total_pieces: int = 0				## 当前主题切片总数
var display_level_id: int = 1			## 大厅按钮展示的关卡编号（全通关时保留在最后一关）
var is_last_piece: bool = false			## 当前解锁的切片是否为本主题的最后一块
var is_last_theme: bool = false			## 当前主题是否为全游戏最后一个主题
var is_all_cleared: bool = false		## 全游戏是否已全部通关
