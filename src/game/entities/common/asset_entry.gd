class_name AssetEntry
extends Resource

## 游戏素材资产描述项实体。
## 记录单个远端素材项的资源 Key、素材类型、下载 URL、MD5 校验码以及启动必下标记。

#region Enums
## 资源素材类型定义
enum Type {
	IMAGE,		## 图像纹理资源（PNG / JPG / WebP ➔ 解码为 Texture2D）
	AUDIO,		## 音频多媒体资源（MP3 / OGG ➔ 解码为 AudioStream）
	BINARY,		## 通用二进制数据文件（PackedByteArray）
}
#endregion

#region Fields
@export var key: String = ""							## 资源全局唯一标识（如 "level_1", "theme_cover_0"）
@export var type: Type = Type.IMAGE						## 资源素材类型
@export var url: String = ""							## 远端资源文件下载地址
@export var md5: String = ""							## 资源文件 MD5 完整性校验码
@export var folder: String = ""							## 本地缓存分类子目录（如 "levels", "themes/0/static"）
@export var filename: String = ""						## 可选的本地自定义磁盘文件名（为空时自动从 url / key 提取）
@export var is_required: bool = false					## 是否为启动必下资源（true 会在启动页加载管线中阻塞下载）
#endregion

## JSON 字段名 → 自定义 Resource 脚本路径映射表。
const SCRIPT_PATHS := {
	"": "res://src/game/entities/common/asset_entry.gd",
}


#region Codec
## 将当前实体编码为 JSON 兼容字典
func encode() -> Dictionary:
	return ResourceCodecUtils.encode(self)


## 从字典数据解码还原为 [AssetEntry] 实体对象
static func decode(encoded: Dictionary, script_paths: Dictionary = SCRIPT_PATHS) -> AssetEntry:
	return ResourceCodecUtils.decode(encoded, script_paths) as AssetEntry


## 克隆一份当前实体的独立深拷贝副本
func clone() -> AssetEntry:
	return ResourceCodecUtils.clone(self, SCRIPT_PATHS) as AssetEntry
#endregion
