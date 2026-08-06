class_name LogService 
extends RefCounted

## 全项目统一日志服务。
##
## 提供 tag 分类 + 级别过滤 + 环形缓冲(崩溃/上报时可导出最近若干条)。
## 由 Bootstrap 最先创建并赋值给 App.log,是后续一切服务的调试基础。
## 详见 docs/modules/log-service.md。
##
## DEBUG/INFO 走 print;WARN 走 push_warning;ERROR 走 push_error
## (后两者会同时出现在 Godot 调试器的错误面板中)。
##
## 每行格式:[code][时间戳] [级别] [tag] 消息[/code],时间戳为系统本地时间
## [code]YYYY-MM-DD HH:MM:SS.mmm[/code](见 [method TimeUtils.now_string])。

enum Level { DEBUG, INFO, WARN, ERROR }

const _LEVEL_TAGS: Array[String] = ["DEBUG", "INFO", "WARN", "ERR"]
const _MAX_ENTRIES: int = 1000   ## 环形缓冲容量,超出丢弃最旧一条

## 低于此级别的日志被过滤,不记录也不输出。发布包可调为 WARN。
var min_level: LogService.Level = Level.DEBUG

var _entries: PackedStringArray = PackedStringArray()


func debug(tag: String, msg: String) -> void:
	_log(Level.DEBUG, tag, msg)


func info(tag: String, msg: String) -> void:
	_log(Level.INFO, tag, msg)


func warn(tag: String, msg: String) -> void:
	_log(Level.WARN, tag, msg)


func error(tag: String, msg: String) -> void:
	_log(Level.ERROR, tag, msg)


## 导出全部缓冲日志为纯文本(供崩溃上报 / 调试面板 / 用户反馈附带)。
func dump() -> String:
	return "\n".join(_entries)


## 清空缓冲。
func clear() -> void:
	_entries.clear()


func _log(level: LogService.Level, tag: String, msg: String) -> void:
	if level < min_level:
		return
	# 时间戳走 TimeUtils(系统墙钟),同时进缓冲,dump() 导出也带时间。
	var line := "[%s] [%s] [%s] %s" % [TimeUtils.now_string(), _LEVEL_TAGS[level], tag, msg]
	_entries.append(line)
	if _entries.size() > _MAX_ENTRIES:
		_entries.remove_at(0)
	match level:
		Level.WARN:
			push_warning(line)
		Level.ERROR:
			push_error(line)
		_:
			print(line)
