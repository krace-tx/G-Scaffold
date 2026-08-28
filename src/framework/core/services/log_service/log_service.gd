class_name LogService
extends RefCounted

## 全项目统一日志服务。
##
## 提供 tag 分类 + 级别过滤 + 环形缓冲(崩溃/上报时可导出最近若干条)。
## Boot 在 [EnvironmentService] 之后创建；[method _init] 按环境设 [member min_level]。
##
## 控制台走 [method @GlobalScope.print_rich]（编辑器 BBCode，终端 ANSI）。
## WARN / ERROR 另外 [code]push_warning[/code] / [code]push_error[/code]，进调试器面板。
## 缓冲 [method dump] 仍是纯文本。

enum LogLevel { DEBUG, INFO, WARN, ERROR }

const LEVEL_TAGS: Array[String] = ["DEBUG", "INFO", "WARN", "ERR"]
const LEVEL_COLORS: Array[String] = [
	"#3B82F6",  # DEBUG 亮蓝 (Tailwind blue-500)
	"#D1D5DB",  # INFO 灰白 (Tailwind gray-300)
	"#F59E0B",  # WARN 橙黄 (Tailwind amber-500)
	"#EF4444",  # ERROR 亮红 (Tailwind red-500)
]
const _MAX_ENTRIES: int = 1000   ## 环形缓冲容量,超出丢弃最旧一条

## 低于此级别的日志被过滤,不记录也不输出。PROD 默认 WARN，其余 DEBUG。
var min_level: LogService.LogLevel = LogLevel.DEBUG

var _entries: PackedStringArray = PackedStringArray()


## [param env] 非空时按环境设 [member min_level]：PROD→WARN，LOCAL/DEV→DEBUG。
func _init(env: EnvironmentService = null) -> void:
	if env == null:
		return
	min_level = LogLevel.WARN if env.is_prod() else LogLevel.DEBUG


#region Public API
func debug(tag: String, msg: String) -> void:
	_log(LogLevel.DEBUG, tag, msg)


func info(tag: String, msg: String) -> void:
	_log(LogLevel.INFO, tag, msg)


func warn(tag: String, msg: String) -> void:
	_log(LogLevel.WARN, tag, msg)


func error(tag: String, msg: String) -> void:
	_log(LogLevel.ERROR, tag, msg)


## 导出全部缓冲日志为纯文本(供崩溃上报 / 调试面板 / 用户反馈附带)。
func dump() -> String:
	return "\n".join(_entries)


## 清空缓冲。
func clear() -> void:
	_entries.clear()


## 静态格式化与控制台富文本打印（供启动初期或无实例快速打印复用）
static func print_raw(level: LogLevel, tag: String, msg: String) -> void:
	var line := "[%s] [%s] [%s] %s" % [TimeUtils.now_string(), LEVEL_TAGS[level], tag, msg]
	print_rich("[color=%s]%s[/color]" % [LEVEL_COLORS[level], line.replace("[", "[lb]")])
	if level == LogLevel.WARN:
		push_warning(line)
	elif level == LogLevel.ERROR:
		push_error(line)
#endregion


#region Internal
func _log(level: LogService.LogLevel, tag: String, msg: String) -> void:
	if level < min_level:
		return

	# 时间戳走 TimeUtils(系统墙钟),同时进缓冲,dump() 导出也带时间。
	var line := "[%s] [%s] [%s] %s" % [TimeUtils.now_string(), LEVEL_TAGS[level], tag, msg]
	_entries.append(line)
	if _entries.size() > _MAX_ENTRIES:
		_entries.remove_at(0)

	print_rich("[color=%s]%s[/color]" % [LEVEL_COLORS[level], line.replace("[", "[lb]")])
	match level:
		LogLevel.WARN:
			push_warning(line)
		LogLevel.ERROR:
			push_error(line)
#endregion
