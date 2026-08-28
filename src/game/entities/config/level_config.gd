class_name LevelConfig
extends Resource

## 关卡与主题相册全局配置数据实体（服务端下发）。
## 集中管理关卡总数、主题总数、大厅相册最少展示数以及全部关卡与主题相册的具体数据。

#region Rules & Statistics
@export var level_count: int = 125					## 生效的关卡总数
@export var theme_count: int = 5					## 生效的主题套图总数
@export var min_display_theme_count: int = 30		## 大厅图库最少展示的主题套图数量
#endregion

#region Levels & Themes
@export var levels: Array[LevelItem] = []			## 关卡数据列表
@export var themes: Array[LevelTheme] = []			## 主题相册数据列表
#endregion

## JSON 字段名 → 自定义 Resource 脚本路径映射表。
const SCRIPT_PATHS := {
	"": "res://src/game/entities/config/level_config.gd",
	"levels": "res://src/game/entities/level/level_item.gd",
	"themes": "res://src/game/entities/level/level_theme.gd",
}


#region Codec
## 将当前实体编码为 JSON 兼容的字典格式。
func encode() -> Dictionary:
	return ResourceCodecUtils.encode(self)


## 从字典数据解码还原为 [LevelConfig] 实体对象。
static func decode(encoded: Dictionary, script_paths: Dictionary = SCRIPT_PATHS) -> LevelConfig:
	return ResourceCodecUtils.decode(encoded, script_paths) as LevelConfig


## 克隆一份当前实体的独立深拷贝副本。
func clone() -> LevelConfig:
	return ResourceCodecUtils.clone(self, SCRIPT_PATHS) as LevelConfig
#endregion
