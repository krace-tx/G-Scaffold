class_name LevelItem
extends Resource

## 单关卡配置数据实体。
## 描述单个拼图关卡的网格行列数、通关倒计时限制以及底图资源信息。

#region Rules & Layout
@export var level_id: int = 1			## 关卡编号（从 1 开始递增）
@export var row: int = 0				## 拼图网格行数
@export var col: int = 0				## 拼图网格列数
@export var time_limit: int = 0			## 关卡时间限制（单位：秒；0 或 -1 表示不设时限）
#endregion

#region Texture Asset
@export var texture_url: String = ""	## 远端关卡完整底图下载 URL
@export var texture_md5: String = ""	## 远端底图文件 MD5 校验码
#endregion

## JSON 字段名 → 自定义 Resource 脚本路径映射表。
const SCRIPT_PATHS := {
	"": "res://src/game/entities/level/level_item.gd",
}


#region Public API
## 计算当前关卡的碎片卡片总数量（行数 × 列数）。
func card_count() -> int:
	return row * col
#endregion


#region Codec
## 将当前实体编码为 JSON 兼容的字典格式。
func encode() -> Dictionary:
	return ResourceCodecUtils.encode(self)


## 从字典数据解码还原为 [LevelItem] 实体对象。
static func decode(encoded: Dictionary, script_paths: Dictionary = SCRIPT_PATHS) -> LevelItem:
	return ResourceCodecUtils.decode(encoded, script_paths) as LevelItem


## 克隆一份当前实体的独立深拷贝副本。
func clone() -> LevelItem:
	return ResourceCodecUtils.clone(self, SCRIPT_PATHS) as LevelItem
#endregion
