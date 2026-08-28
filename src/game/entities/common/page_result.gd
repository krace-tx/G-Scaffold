class_name PageResult
extends Resource

## 统一分页数据结构实体（对齐后端 PageResult[T] 模型）。[br]
## 封装分页查询接口返回列表、分页元数据与总页数。

#region Fields
@export var total: int = 0				## 总记录条数
@export var page: int = 1				## 当前页码（从 1 开始）
@export var page_size: int = 20			## 每页数据条数
@export var total_pages: int = 0		## 总页数
@export var items: Array = []			## 当前页数据列表（元素可为 Resource / Dictionary / 基本类型）
@export var extra: Dictionary = {}		## 附加元数据（如服务端附带的 self_info 自身排位快照等）
#endregion

## JSON 字段名 → 自定义 Resource 脚本路径映射表。
const SCRIPT_PATHS := {
	"": "res://src/game/entities/common/page_result.gd",
}


#region Public API
## 是否有下一页
func has_next() -> bool:
	return page < total_pages


## 是否有上一页
func has_previous() -> bool:
	return page > 1


## 当前列表是否为空
func is_empty() -> bool:
	return items.is_empty()
#endregion


#region Codec
## 将当前实体编码为 JSON 兼容字典
func encode() -> Dictionary:
	return ResourceCodecUtils.encode(self)


## 从字典数据解码还原为 [PageResult] 实体对象
static func decode(encoded: Dictionary, script_paths: Dictionary = SCRIPT_PATHS) -> PageResult:
	return ResourceCodecUtils.decode(encoded, script_paths) as PageResult


## 克隆一份当前实体的独立深拷贝副本
func clone() -> PageResult:
	return ResourceCodecUtils.clone(self, SCRIPT_PATHS) as PageResult
#endregion
