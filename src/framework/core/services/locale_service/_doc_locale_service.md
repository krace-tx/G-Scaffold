# LocaleService

## 核心

表由引擎把 CSV 导入成 `.translation`，再经项目设置挂到 `TranslationServer`。本服务只选语言并 `TranslationServer.set_locale`。

查词不经本服务：静态 UI 走 Auto Translate，动态文案直接 `tr()` / `tr_n()`。

---

## 细节

- 入口：`App.locale`，boot 时 `initialize()`。语言必须已在项目设置里加载，否则 `set_language` 返回 `Result.err`。
- 启动选语言：`LocaleConfig.default_language`（英文 `EN_US`）→ 设备语言 → 已加载的第一门。
- 切语言成功后发 `Bus.locale_changed`。静态控件由引擎重绘；带参数的 `text` 要自己再赋一次。
- 唯一字典：`res://src/assets/translations/i18n.csv`。`LocaleConfig` 只回答表路径和默认语言，不进 `EnvironmentService`。
- 表里**只留仍被 tscn / `tr()` 引用的 key**。删场景或改文案时同步删行。
- key 与贴图同构：`{scene}_{slot}`，小写蛇形，全局不重复。`scene` 为 launcher / lobby / level / gallery / leaderboard / common / popup_*。占位符写在译文里（`%d` / `%s`），不写进 key。静态控件把 key 填进 `text` 走 Auto Translate；带参数或拼接（如省略号）用 `tr("key")`。
- `_tscn` 列是给人看的：相对 `src/game/scenes/` 的场景路径，多个用 `|` 分隔。列名以下划线开头，引擎当注释丢掉，不生成语言包。

```
locale_service/
├── locale_service.gd    门面：initialize / set_language
└── locale_config.gd     csv_path、default_language、Language 枚举
```

---

## 样例

```gdscript
App.locale.set_language(LocaleConfig.Language.EN_US)

func _ready() -> void:
	Bus.locale_changed.connect(_refresh_describe)
	_refresh_describe()

func _refresh_describe() -> void:
	_describe.text = "%s %s" % [tr("launcher_loading"), ".".repeat(_dot_count)]
```
