# Services (基础服务层)

## 核心

提供独立于游戏业务的基础设施级通用服务集合。
通过全局聚合根（[code]App[/code] 单例）向全框架与业务逻辑提供统一的强类型访问点。
各服务之间职责高度正交、严格解耦，底层的网络重试、加密落盘、BGM 交叉淡变等技术细节对调用方完全透明，所有可失败操作均通过 [code]Result[/code] 契约显式暴露。

---

## 细节

- **服务聚合与启动**：
  - 由 [code]BootPipeline[/code] 启动管线在游戏冷启动阶段按依赖层级分批初始化，并自动挂载至 [code]App[/code] 场景树。
  - 所有全局服务均挂载在 [code]App[/code] 聚合根下，业务代码通过 [code]App.{service_name}[/code] 直接调用。
- **服务矩阵与核心职责**：
  - `App.env`（[EnvironmentService]）：环境判定（Local/Dev/Prod），提供只读环境类型与环境名称查询。
  - `App.log`（[LogService]）：结构化分级日志（debug/info/warn/error），支持模块 Tag 过滤与格式化输出。
  - `App.net`（[NetworkService]）：HTTP 传输通道，内建空闲请求池、Bearer Token 自动注入、指数退避重试（5xx / 断网）与超时熔断。
  - `App.persist`（[PersistService]）：数据持久化，支持本地文件系统与云端数据存取，提供内存脏数据自动同步策略。
  - `App.time`（[TimeService]）：防作弊权威时间源，基于本地单调 tick 与服务器 Unix 毫秒对齐校准，提供秒/毫秒时间戳与可信度查询（`is_trusted`）。
  - `App.locale`（[LocaleService]）：多语言选定与切换，与 Godot 原生 `TranslationServer` 联动，语言变更自动触发 `Bus.locale_changed`。
  - `App.asset`（[AssetService]）：资产加载与缓存池，提供内存/磁盘二级缓存管理与异步加载调度。
  - `App.scene`（[SceneService]）：顶层场景路由门面与栈状态机，支持成对流式转场动画与防重入调度。
  - `App.audio`（[AudioService]）：BGM/SFX 双总线音量管理、BGM 跨场景交叉淡变（Cross-Fade）与 SFX 播放器池复用。

```text
src/framework/core/services/
├── _doc_services.md          # 本模块架构与使用文档
├── asset_service/            # 资产服务：统一资产加载池、内存/磁盘缓存管理
├── audio_service/            # 音频服务：BGM 交叉淡变、SFX 播放器池与总线音量控制
├── environment_service/      # 环境服务：LOCAL / DEV / PROD 运行环境判定
├── locale_service/           # 多语言服务：语言匹配、动态切换与 TranslationServer 联动
├── log_service/              # 日志服务：结构化分级日志 (debug / info / warn / error)
├── network_service/          # 网络服务：HTTP 连接池、指数退避重试与 Token 注入
├── persist_service/          # 持久化服务：本地与云端数据安全序列化落盘
└── time_service/             # 时间服务：防作弊单调权威时钟与服务器对齐校准
```

---

## 样例

```gdscript
# 1. 结构化日志输出
App.log.info("Lobby", "Player entered main lobby.")

# 2. 运行环境分支判定
if App.env.is_dev():
    App.log.debug("DebugTool", "Dev mode enabled.")

# 3. HTTP 网络请求 (必须 await)
var res := await App.net.get_request("https://api.example.com/v1/config")
if res.is_ok():
    var response_dict: Dictionary = res.value
else:
    App.log.error("Network", "Failed to fetch config: %s" % res.error)

# 4. 防作弊权威时间获取
if App.time.is_trusted():
    var server_now_sec := App.time.now()
    var server_now_ms := App.time.now_msec()

# 5. 音频播放与 BGM 交叉淡变
App.audio.play_sfx_by_path(AudioCatalog.SFX_CLICK)
App.audio.play_bgm_by_path("res://src/assets/audio/bgm_main.mp3", 0.8)

# 6. 多语言动态切换
App.locale.set_language(LocaleConfig.Language.ZH_CN)
```
