# SaveService 模块文档

> status: active | 最后更新: 2026-07-04 | 代码位置: `res://src/framework/core/save_service.gd`

## 职责与边界

**做什么**:玩家存档的加载、迁移、持久化。存档结构固定为 `{ "version": N, "data": {...} }` 的 JSON,加载时若版本落后则按迁移链逐级升级;损坏档自动备份后走空档兜底。见 [ADR-0003](../architecture/decisions/0003-versioned-json-saves.md)。

**明确不做什么**:
- 不定义存档字段 schema——那是各游戏的事,SaveService 只提供 `get_value`/`set_value` 通用读写
- 不做自动存档节流/定时——调用方决定何时 `flush`(切后台由 App 统一触发)
- 不加密/签名——前期用明文 JSON(可调试);上线加固时在外层加密,不改本类结构

## 公开 API

```gdscript
func load_or_create() -> Result           # 加载+迁移;缺失/损坏走兜底;I/O 失败才 err
func flush() -> Result                     # 写回磁盘
func get_value(key: String, default = null) -> Variant
func set_value(key: String, value) -> void # 仅改内存,需再 flush
func set_migrations(migrations: Dictionary) -> void  # 注册 {版本N: Callable(data)->data}
```

**键一律用 String**,不要用 StringName——JSON 往返后键会变回 String,用 StringName 读会静默 miss。

## 迁移链

`CURRENT_VERSION` 是代码认识的结构版本。加字段/改结构时 +1,并注册一个把旧版升到新版的函数:

```gdscript
App.save.set_migrations({
    1: func(d): d["settings"] = {}; return d,   # v1 -> v2:新增 settings
    2: func(d): d["coins"] = d.get("gold", 0); return d,  # v2 -> v3:gold 改名 coins
})
```

加载 v1 的旧档到 CURRENT_VERSION=3 时,`_run_migrations` 依次调 1→2、2→3,日志可见 `migrated save 1 -> 3`。

## Bus 事件

无(M2 暂不发存档事件)。

## 依赖

- 依赖:`App.log`
- 初始化时机:Bootstrap 阶段 2,`load_or_create` 在此调用;切后台时 `App._notification` 触发 `flush`

## 持有的数据

- `_data`:内存中的存档 data 部分,进程生命周期存在
- 磁盘:`user://save.json`;损坏备份 `user://save.corrupt.<时间戳>.json`

## 失败策略

- 文件不存在:空档,`ok`
- JSON 解析失败(损坏):备份原文件 + 走空档 + `ok`(**不阻断**——玩家无法自修损坏档,阻断等于锁死)
- 磁盘 I/O 读失败:`err`(Bootstrap 阶段 2 据此阻断重试)
- 写失败:`flush` 返回 `err`

## 测试要点

- 已无头验证(2026-07-04):迁移链 v1→v3 逐级、写→flush→新实例读一致、损坏档不崩+空档兜底+备份生成
- 后续单测(M6):`_run_migrations` 跳版本/缺失迁移函数、超大档性能
