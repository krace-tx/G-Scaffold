class_name UuidUtils
extends RefCounted

## UUID 生成与短码互转工具类。
##
## 生成符合 RFC 4122 的随机 UUID（version 4），并可将其无损压缩成 22 字符的
## base64url 短码（便于放进 URL / 分享链接），再原样还原。
## 底层用 [Crypto.generate_random_bytes] 取密码学安全随机源——比 [method @GlobalScope.randi]
## 更适合做全局唯一标识（存档 id、网络会话 id、埋点 traceId 等）。
## 纯无状态工具函数，不依赖场景树或外部单例。

#region Constants & Enums
const _UUID_BYTE_COUNT: int = 16   ## UUID 为 128 位，即 16 字节。
const _HEX_CHAR_COUNT: int = 32    ## 去掉连字符后的十六进制字符数。
const _TOKEN_LENGTH: int = 22      ## 16 字节的 base64url 短码长度（无填充）。

# UUID v4 的两处版本/变体标记位（RFC 4122 §4.4）：
const _VERSION_BYTE_INDEX: int = 6   # 第 7 字节高 4 位固定为 0100（version 4）
const _VARIANT_BYTE_INDEX: int = 8   # 第 9 字节高 2 位固定为 10（RFC 4122 variant）

# 每段十六进制字符长度，对应 8-4-4-4-12 分组。
const _SEGMENT_LENGTHS: Array[int] = [8, 4, 4, 4, 12]

# 短码走 base64url（RFC 4648 §5）：URL 安全字符集 + 无填充。
const _BASE64URL_ALPHABET: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
const _BASE64_PADDING: String = "=="   # 22 字符补到 24（4 的倍数）才能被标准 base64 解码。
#endregion

#region Public API
## 生成一个随机 UUID（version 4），返回小写带连字符的标准字符串，[br]
## 形如 [code]f47ac10b-58cc-4372-a567-0e02b2c3d479[/code]（36 字符）。[br]
## 随机源为密码学安全的 [Crypto]，碰撞概率可忽略，可直接用作全局唯一标识。
static func v4() -> String:
	var crypto := Crypto.new()
	var bytes := crypto.generate_random_bytes(_UUID_BYTE_COUNT)
	_stamp_version_and_variant(bytes)
	return _format_bytes(bytes)


## 将标准 UUID 字符串压缩为 22 字符的 base64url 短码（URL 安全、无填充）。[br]
## 例：[code]550e8400-e29b-41d4-a716-446655440000[/code] → [code]VQ6EAOKbQdSnFkRmVUQAAA[/code]。[br]
## 返回 [Result]：成功时 [member Result.value] 为短码字符串；[param uuid] 不是合法
## 32 位十六进制 UUID 时失败（[member Result.error] 为原因）。可用 [method from_share_token] 还原。
static func to_share_token(uuid: String) -> Result:
	var hex := uuid.replace("-", "")
	if hex.length() != _HEX_CHAR_COUNT or not hex.is_valid_hex_number(false):
		return Result.err("无效 UUID，无法生成短码: %s" % uuid)
	var b64 := Marshalls.raw_to_base64(_hex_to_bytes(hex))
	return Result.ok(_to_base64url(b64))


## 将 [method to_share_token] 生成的短码还原为标准 UUID 字符串。[br]
## 返回 [Result]：成功时 [member Result.value] 为小写带连字符的 UUID；[param token]
## 长度/字符集非法或解码后字节数异常时失败——短码常来自外部（URL、用户粘贴），
## 属可预期失败，调用方禁止静默吞错。
static func from_share_token(token: String) -> Result:
	if not _is_valid_token(token):
		return Result.err("无效分享短码: %s" % token)
	var b64 := token.replace("-", "+").replace("_", "/") + _BASE64_PADDING
	var bytes := Marshalls.base64_to_raw(b64)
	if bytes.size() != _UUID_BYTE_COUNT:
		return Result.err("分享短码解码后字节数异常: %s" % token)
	return Result.ok(_format_bytes(bytes))
#endregion

#region Internal
## 就地写入 version(4) 与 variant(RFC 4122) 标记位。
static func _stamp_version_and_variant(bytes: PackedByteArray) -> void:
	# 高 4 位清零后置为 0100，即 version 4。
	bytes[_VERSION_BYTE_INDEX] = (bytes[_VERSION_BYTE_INDEX] & 0x0F) | 0x40
	# 高 2 位清零后置为 10，即 RFC 4122 variant。
	bytes[_VARIANT_BYTE_INDEX] = (bytes[_VARIANT_BYTE_INDEX] & 0x3F) | 0x80


## 按 8-4-4-4-12 分组把 16 字节拼成带连字符的小写十六进制 UUID。
static func _format_bytes(bytes: PackedByteArray) -> String:
	var hex := bytes.hex_encode()   # 32 个十六进制字符，已是小写
	var segments := PackedStringArray()
	var cursor := 0
	for length in _SEGMENT_LENGTHS:
		segments.append(hex.substr(cursor, length))
		cursor += length
	return "-".join(segments)


## 把 32 位十六进制字符串按每两位解析成 16 字节。调用方需先确保是合法 hex。
static func _hex_to_bytes(hex: String) -> PackedByteArray:
	var bytes := PackedByteArray()
	var cursor := 0
	while cursor < hex.length():
		bytes.append(hex.substr(cursor, 2).hex_to_int())
		cursor += 2
	return bytes


## 标准 base64 → base64url：+/ 换成 -_，去掉尾部 = 填充。
static func _to_base64url(standard_b64: String) -> String:
	return standard_b64.replace("+", "-").replace("/", "_").rstrip("=")


static func _is_valid_token(token: String) -> bool:
	if token.length() != _TOKEN_LENGTH:
		return false
	for ch in token:
		if _BASE64URL_ALPHABET.find(ch) == -1:
			return false
	return true
#endregion
