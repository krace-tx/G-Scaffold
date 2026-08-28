class_name LevelPiece
extends Resource

## 主题拼图碎片元数据实体。
## 记录单块碎片的纹理下载地址、校验码以及在整张主题大图上的布局尺寸与对齐偏移。

#region Texture Asset
@export var texture_url: String = ""			## 碎片纹理图片下载 URL
@export var texture_md5: String = ""			## 碎片纹理图片 MD5 校验码
#endregion

#region Layout & Metrics
@export var piece_size: Vector2 = Vector2.ZERO	## 碎片贴图尺寸（宽、高）
@export var piece_pos: Vector2 = Vector2.ZERO	## 碎片左上角相对于整张大图左上角的像素偏移坐标 (x, y)
#endregion

## JSON 字段名 → 自定义 Resource 脚本路径映射表。
const SCRIPT_PATHS := {
	"": "res://src/game/entities/level/level_piece.gd",
}


#region Codec
## 将当前实体编码为 JSON 兼容的字典格式。
func encode() -> Dictionary:
	return ResourceCodecUtils.encode(self)


## 从字典数据解码还原为 [LevelPiece] 实体对象。
static func decode(encoded: Dictionary, script_paths: Dictionary = SCRIPT_PATHS) -> LevelPiece:
	return ResourceCodecUtils.decode(encoded, script_paths) as LevelPiece


## 克隆一份当前实体的独立深拷贝副本。
func clone() -> LevelPiece:
	return ResourceCodecUtils.clone(self, SCRIPT_PATHS) as LevelPiece
#endregion
