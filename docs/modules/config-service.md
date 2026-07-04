# ConfigService 模块文档

> status: active | 最后更新: 2026-07-04 | 代码位置: `res://src/framework/core/config_service.gd`

## 职责与边界

**做什么**:运营/远程配置的只读访问,三层合并——`remote > local > defaults`。业务用 `get_value` 系读开关、数值、AB 参数,永远有值(defaults 兜底)。

**明确不做什么**:
- 不在运行时改配置——想改行为改数据源(defaults / 远程),不提供 `set_value`
- 不负责拉取远程(那是 NetworkService 的传输职责,M4 接通后调 `apply_remote`)
- 不管玩家存档——那是 SaveService。配置是"全体玩家/运营下发",存档是"本玩家进度"

## 三层来源

| 层 | 来源 | 优先级 | 何时有值 |
|---|---|---|---|
| remote | 服务器本次下发 | 最高 | M4 拉取成功后 `apply_remote` |
| local | 上次远程结果的本地缓存 | 中 | 启动 `load_local`(离线/拉取失败兜底) |
| defaults | 代码内置默认 | 最低 | 游戏启动 `set_defaults` |

## 公开 API

```gdscript
func set_defaults(defaults: Dictionary) -> void   # 启动时设一次
func get_value(key: String, fallback = null) -> Variant
func get_bool(key, fallback := false) -> bool
func get_int(key, fallback := 0) -> int
func get_number(key, fallback := 0.0) -> float
func get_string(key, fallback := "") -> String
func load_local() -> void                          # 加载本地缓存
func apply_remote(remote: Dictionary) -> void      # M4:应用远程 + 落盘缓存
```

键用 String(与 JSON 一致)。

## Bus 事件

无(M2)。M4 接通远程后,`apply_remote` 可考虑发 `config_changed`,届时再加(YAGNI)。

## 依赖

- 依赖:`App.log`(缓存写失败告警)
- 初始化时机:Bootstrap 阶段 2 创建 + `load_local`;阶段 4(M4)`apply_remote`

## 持有的数据

- `_defaults` / `_local` / `_remote` 三个 Dictionary,进程生命周期存在
- 磁盘:`user://config_cache.json`(远程结果缓存)

## 失败策略

- 本地缓存文件不存在/解析失败:静默跳过(defaults 仍兜底,不影响启动)
- 缓存写失败:warn 日志,不阻断

## 测试要点

- 已无头验证(2026-07-04):remote 覆盖 local 覆盖 defaults 的优先级、缺失键返回 fallback
- 后续单测(M6):load_local 损坏缓存的容错、apply_remote 落盘往返
