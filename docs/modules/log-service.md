# LogService 模块文档

> status: active | 最后更新: 2026-07-04 | 代码位置: `res://src/framework/core/log_service.gd`

## 职责与边界

**做什么**:全项目统一的日志出口——按 tag 分类、按级别(DEBUG/INFO/WARN/ERROR)过滤,并维护一个环形缓冲供崩溃上报/调试面板/用户反馈导出最近日志。是 Bootstrap 第一个创建的服务,后续所有阶段和服务都依赖它。

**明确不做什么**:
- 不做远程日志上传——那是运营/监控基建,若要接入,包一层订阅 `dump()` 的上报服务,不塞进 LogService 本身
- 不做结构化日志(JSON 字段)——当前只输出格式化字符串,够用为止,过度设计留到真需要时再加

## 公开 API

```gdscript
func debug(tag: String, msg: String) -> void   # 记录 DEBUG 级日志
func info(tag: String, msg: String) -> void    # 记录 INFO 级日志
func warn(tag: String, msg: String) -> void    # 记录 WARN 级(同时 push_warning)
func error(tag: String, msg: String) -> void   # 记录 ERROR 级(同时 push_error)
func dump() -> String                          # 导出全部缓冲日志为纯文本
func clear() -> void                           # 清空缓冲
```

## 行格式

每行:`[时间戳] [级别] [tag] 消息`,例如
`[2026-07-04 23:37:51.851] [INFO] [boot] phase 1/6: log service ready`。
时间戳为系统本地时间 `YYYY-MM-DD HH:MM:SS.mmm`(毫秒便于排序快速事件),经
`TimeUtils.now_string()` 生成——走系统墙钟而非 `App.time`,因为日志早于 M4 校时就要能用。缓冲与 `dump()` 导出都带时间戳。

## Bus 事件

无。LogService 不发送也不监听 Bus 事件——纯粹的被动服务。

## 依赖

- 依赖:仅 `TimeUtils.now_string()`(纯静态时间格式化,无场景树/App 依赖),用于行时间戳
- 初始化时机:Bootstrap 阶段 1(见 [boot-sequence.md](../architecture/boot-sequence.md)),赋值给 `App.log`,必须在所有其他阶段之前完成

## 持有的数据

- `_entries: PackedStringArray` —— 环形缓冲,容量 `_MAX_ENTRIES = 500`,超出丢弃最旧一条,进程生命周期内存在,不持久化
- `min_level` —— 运行时可调的过滤阈值,默认 `DEBUG`,发布包可调为 `WARN`

## 失败策略

- 本身不会失败(纯内存操作),因此 Bootstrap 阶段 1 标注为"不可失败"
- 调用方传入非法 tag/msg 不做校验——这是开发期工具,不是面向用户输入的边界

## 测试要点

- 编辑器:直接调用 `App.log.debug/info/warn/error` 观察输出与调试器错误面板
- 无头验证:已用 `SceneTree` 脚本跑通 12 项断言(级别路由、环形缓冲计数、`min_level` 过滤),见开发历史记录
- 单测覆盖点(M6):环形缓冲超容量丢弃最旧、`min_level` 过滤边界、`dump()` 格式
