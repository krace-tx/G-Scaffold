class_name BaseResponse
extends Resource

## 统一 API 接口响应数据实体（对齐后端 BaseResponse[T] 模型）。[br]
## 封装标准 HTTP API 返回外层：状态码、提示消息与业务数据载荷。

#region Fields
@export var code: int = 200				## 响应状态码（200 为成功）
@export var msg: String = "success"		## 响应提示信息
@export var data: Variant = null		## 业务数据载荷（可以是 Dictionary、Resource、Array 等）
#endregion

## JSON 字段名 → 自定义 Resource 脚本路径映射表。
const SCRIPT_PATHS := {
	"": "res://src/game/entities/common/base_response.gd",
}


#region Public API
## 本次网络请求是否成功（状态码为 200）
func is_success() -> bool:
	return code == 200


## 将业务载荷解析为指定的自定义 Resource 实体。[br]
## [param script_paths]：自定义实体属性键与脚本路径映射字典（可选）。
func decode_data(script_paths: Dictionary = {}) -> Resource:
	if data is Dictionary:
		return ResourceCodecUtils.decode(data as Dictionary, script_paths)
	return null
#endregion


#region Response Parser
## 从网络响应（或本地缓存字典）中提取内层业务载荷 Dictionary。[br]
## 若为 BaseResponse 信封结构，自动校验状态码并提取 data；若已是纯业务字典则原样返回。
static func extract_payload(raw: Variant) -> Dictionary:
	if not raw is Dictionary:
		return {}
	var dict := raw as Dictionary
	if dict.has("code"):
		if int(dict.get("code", 0)) != 200:
			App.log.warn("BaseResponse", "Response code error: %s (msg: %s)" % [dict.get("code"), dict.get("msg", "")])
			return {}
		var data_val: Variant = dict.get("data")
		return data_val if data_val is Dictionary else {}
	return dict


## 一步完成：响应状态校验 ➔ 信封拆包 ➔ 强类型实体解码。[br]
## [param raw]：网络响应字典或本地缓存字典；[br]
## [param decoder]：目标实体解码方法（如 [method GameConfig.decode]）；[br]
## 返回强类型 Resource 实体对象，失败返回 null。
static func parse_data(raw: Variant, decoder: Callable) -> Resource:
	var payload := extract_payload(raw)
	if payload.is_empty():
		return null
	return decoder.call(payload) as Resource
#endregion


#region Codec
## 将当前实体编码为 JSON 兼容字典
func encode() -> Dictionary:
	return ResourceCodecUtils.encode(self)


## 从字典数据解码还原为 [BaseResponse] 实体对象
static func decode(encoded: Dictionary, script_paths: Dictionary = SCRIPT_PATHS) -> BaseResponse:
	return ResourceCodecUtils.decode(encoded, script_paths) as BaseResponse


## 克隆一份当前实体的独立深拷贝副本
func clone() -> BaseResponse:
	return ResourceCodecUtils.clone(self, SCRIPT_PATHS) as BaseResponse
#endregion
