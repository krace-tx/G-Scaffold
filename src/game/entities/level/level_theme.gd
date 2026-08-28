class_name LevelTheme
extends Resource

## 主题相册数据实体。
## 记录一套拼图大插画（主题相册）的元数据、封面信息以及所有关联的动态与静态拼图碎片列表。

#region Metadata
@export var index: int = 0						## 主题套图序号（从 0 开始）
@export var title: String = ""					## 主题标题名称
#endregion

#region Cover Asset
@export var cover_url: String = ""				## 主题封面大图下载 URL
@export var cover_md5: String = ""				## 主题封面大图 MD5 校验码
#endregion

#region Piece Lists
@export var anim_pieces: Array[LevelPiece] = []		## 动态动画碎片元数据列表
@export var static_pieces: Array[LevelPiece] = []	## 静态碎片元数据列表
#endregion

## JSON 字段名 → 自定义 Resource 脚本路径映射表。
const SCRIPT_PATHS := {
	"": "res://src/game/entities/level/level_theme.gd",
	"anim_pieces": "res://src/game/entities/level/level_piece.gd",
	"static_pieces": "res://src/game/entities/level/level_piece.gd",
}


#region Codec
## 将当前实体编码为 JSON 兼容的字典格式。
func encode() -> Dictionary:
	return ResourceCodecUtils.encode(self)


## 从字典数据解码还原为 [LevelTheme] 实体对象。
static func decode(encoded: Dictionary, script_paths: Dictionary = SCRIPT_PATHS) -> LevelTheme:
	return ResourceCodecUtils.decode(encoded, script_paths) as LevelTheme


## 克隆一份当前实体的独立深拷贝副本。
func clone() -> LevelTheme:
	return ResourceCodecUtils.clone(self, SCRIPT_PATHS) as LevelTheme
#endregion
