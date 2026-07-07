# 框架开发计划

> status: M0~M6 全部完成 ✅(不含真机 SDK 联调)| 最后更新: 2026-07-06 | 预估基准:1 名开发者全职

## 总目标

在 g-scaffold 中实现框架内核与全部基础服务,达到两个"完成"标准:

1. **新游戏可直接以此为起点**:F5 能跑通"启动 → 主菜单 → 进关卡 → 弹窗 → 看广告(Null)→ 发奖 → 存档"的完整演示流程。
2. **现有项目可开始绞杀者迁移**:框架 API 稳定,迁移轨道(见下)可启动。

## 里程碑总览

| 里程碑 | 内容 | 预估 | 前置 | 状态 |
|---|---|---|---|---|
| M0 | 内核四件套:App / Bus / LogService / Bootstrap | 2~3 天 | — | ✅ 已完成 |
| M1 | SceneService + UIService(场景与 UI 生命周期) | 4~6 天 | M0 | ✅ 已完成 |
| M2 | SaveService + ConfigService + TimeService(数据层) | 3~4 天 | M0 | ✅ 已完成 |
| M3 | 平台防腐层:契约 + Null 全家桶 + Android/iOS 骨架 | 4~6 天 | M0 | ✅ 已完成(不含真机联调)|
| M4 | NetworkService(传输层) | 3~4 天 | M0, M2 | ✅ 已完成 |
| M5 | AudioService + AssetService | 3~4 天 | M0 | ✅ 已完成 |
| M6 | 质量收口:检查脚本、调试面板、单测、全流程 Demo | 3~5 天 | M1~M5 | ✅ 已完成 |

并行性:M0 完成后,M1 / M2 / M3 / M5 相互独立,可任意穿插;M4 依赖 M2(需要 TimeService 校时)。单人开发建议按编号顺序做,**M1 优先于一切**——它是现有项目混乱的重灾区,迁移收益最大。

进度更新规则:完成一项勾选一项;里程碑完成时更新本表状态列与 `modules/README.md` 索引,并在对应模块文档把 `draft` 改为 `active`。

---

## M0 内核四件套(2~3 天)

一切的地基。完成前不写任何其他代码。

- [x] `framework/core/result.gd` — `Result` 类型(`ok/err`、`value/error`),全项目错误处理的统一载体 ✅ 无头验证通过
- [x] `framework/core/log_service.gd` — tag + 级别(debug/info/warn/error)、环形缓冲、可导出日志文本 ✅ 无头验证通过
- [x] `framework/autoloads/bus.gd` — App 领域初始信号(`app_paused`/`app_resumed`,过去式);`scene_changed` 等其他领域信号留到对应里程碑落地时再加(YAGNI) ✅ 无头验证通过
- [x] `framework/autoloads/app.gd` — `log: LogService` 类型化字段(其余服务字段随 M1~M5 各自补充);`_notification` 接管切后台/恢复并转发 Bus 事件 ✅ 无头验证通过
- [x] `framework/core/bootstrap.gd` + `game/scenes/boot.tscn` + `game/scenes/main_menu.tscn`(占位) — 阶段管线骨架(6 阶段,未实现的阶段打日志跳过)✅ 无头验证通过
- [x] `project.godot`:注册 App / Bus 两个 Autoload,主场景设为 `boot.tscn`,开启 `untyped_declaration = error` 警告 ✅
- [x] 文档:`modules/log-service.md` ✅

**验收(DoD)**:F5 启动,控制台按序输出各阶段日志,最终切到一个占位主菜单场景;切后台/恢复(编辑器内用窗口失焦模拟)能看到对应 Bus 事件日志;无任何脚本报错。

✅ **M0 已完成并通过无头验证**(2026-07-04):
- 6 阶段日志按序输出,末尾场景切换到 `MainMenu`(已核实 `get_tree().current_scene.name == "MainMenu"`)
- `NOTIFICATION_APPLICATION_PAUSED/RESUMED` → `App._notification` → `Bus.app_paused`/`Bus.app_resumed` 双向验证通过
- 踩坑记录:`change_scene_to_file` 不能在 Boot 根节点自己的 `_ready()` 同帧调用(树还在处理"添加子节点",会报 `remove_child` 忙碌错误)。当时用 `call_deferred` 解决;M1 落地 SceneService 后,`replace()` 内部先 `await` 转场淡出,真正切场景时已经过了好几帧,这个坑自然消失,`call_deferred` 已从 bootstrap.gd 移除

## M1 场景与 UI 生命周期(4~6 天)

- [x] `framework/managers/base_scene.gd` — `_on_enter(params)/_on_exit()` 异步契约 ✅ 无头验证通过
- [x] `framework/managers/scene_service.gd` — 按 [modules/scene-service.md](../modules/scene-service.md) 规格实现:`replace` + `load_threaded` 异步加载 + 转场遮罩 + 10s 超时保护 + 排队防并发 ✅ 无头验证通过(含失败路径与并发排队压测)
- [x] `resource/scripts/scene_registry_entry.gd` + `resource/scripts/scene_registry.gd` + `resource/data/scene_registry.tres` + `SceneIds` 常量类 ✅ 无头验证通过
✅ **前 3 项已完成并通过无头验证**(2026-07-04):
- 完整链路走通:Bootstrap 阶段 6 → `App.scenes.replace(SceneIds.MAIN_MENU)` → 注册表查路径 → `load_threaded` 异步加载 → 转场淡出/淡入 → `change_scene_to_packed` → `MainMenu._on_enter` → `Bus.scene_changed`
- 失败路径验证:未知场景 id → `App.log.error` + `Bus.scene_change_failed`,停留在当前场景,不留黑屏
- 排队防并发验证:连续 3 次 `replace()` 不等待地调用,`_is_switching` 立即置真,4 次(含首次)`scene_changed` 按顺序逐一触发,队列最终清空,无并发/丢失
- 命名冲突:`SceneRegistry.get_path()` 与 `Resource` 内置的 `get_path()`(返回资源自身磁盘路径)签名不兼容,GDScript 视为非法覆写、直接报编译错误(不是简单警告,`@warning_ignore` 无法压下),改名为 `resolve_path` 解决
- **重要踩坑**:GDScript 的 lambda 闭包捕获局部变量是**按值快照**,不是按引用。`_run_on_enter` 最初用一个 `bool finished` 变量在 fire-and-forget lambda 内部置真等待完成,结果外层循环永远看不到这个变化,导致协程空转到 10 秒超时——headless 测试中因为提前 `quit()` 而表现为进程挂起 + `ObjectDB instances leaked at exit`。修复:改用单元素 `Array`(引用类型)做可变完成标记。这个坑具有普遍性,后续任何"fire-and-forget + 完成标记"模式都要避免用 bool/int 等值类型做跨闭包共享状态,已记入 [scene_service.gd](../../src/framework/managers/scene_service.gd) 内联注释

- [x] `resource/scripts/res_paths.gd`(`ResPaths` 常量类)— 集中管理框架硬编码的 `res://` 资源文件路径。已把 `SceneService._REGISTRY_PATH` 迁为 `ResPaths.SCENE_REGISTRY`,ui_service 用 `ResPaths.UI_REGISTRY` ✅
- [x] `framework/managers/base_ui.gd` — `_on_open/_on_close/_on_back` 契约(extends Control)✅
- [x] `framework/managers/ui_service.gd` — 分层 CanvasLayer(HUD=10/Window=20/Popup=30/Toast=40/Loading=50/Debug=110,与遮罩 `layer=100` 错开)、每层栈、`open/close/handle_back`、KEEP/DESTROY 缓存策略 ✅ 无头验证通过
- [x] `resource/data/ui_registry.tres` + `resource/scripts/ui_registry.gd` + `ui_registry_entry.gd`(Layer/Cache 枚举)+ `UIIds` 常量类 ✅
- [x] 占位场景与 UI:main_menu(已有)、level(空关卡)、settings_panel(设置弹窗);SceneIds 加 `LEVEL`,UIIds 加 `SETTINGS` ✅
- [x] 文档:`modules/ui-service.md`(active);`scene-service.md` 状态改 `active`;`modules/README.md` 索引更新 ✅
- [x] 接线:`App.ui` 字段 + `App._notification` 接管 `NOTIFICATION_WM_GO_BACK_REQUEST` → `handle_back()`;Bus 加 `scene_changed`/`scene_change_failed`/`ui_opened`/`ui_closed`;Bootstrap 内核阶段一并创建 SceneService + UIService ✅

**验收**:主菜单 → 关卡 → 返回主菜单,转场无黑屏残留;设置弹窗开/关/Android 返回键(编辑器用 ui_cancel 模拟)三条路径正确;连续快速点击切场景不崩溃。

✅ **M1 已完成并通过无头验证**(2026-07-04):
- 场景往返:`replace(LEVEL)` → `current_scene == "Level"` → `replace(MAIN_MENU)`,`scene_changed` 逐次触发,无黑屏
- UI 生命周期:`open(SETTINGS)` 返回实例、`is_open` 开关正确、`close` 后移除;`ui_opened`/`ui_closed` 事件按序发出
- 返回键路由:开弹窗后 `handle_back()` 关掉栈顶弹窗并返回 true;空栈时返回 false(交场景级)
- **踩坑**:`class_name` 脚本里"内部 `enum` 被用作自身成员类型"(如 `var min_level: Level`)在 autoload 编译级联中会触发 Godot 幻象报错(`Cannot assign LogService.Level to Level`),连累依赖链全部编译失败。根因不在 ui_service 而在 log_service 自身。修复:把自引用处**全限定**为 `LogService.Level`。此坑对所有"class_name + 自引用 enum 类型标注"通用

## M2 数据层(3~4 天)

- [x] `framework/core/save_service.gd` — 版本化 JSON(见 [ADR-0003](../architecture/decisions/0003-versioned-json-saves.md))、迁移链(`_run_migrations` 纯函数)、`flush()`、损坏档备份兜底 ✅ 无头验证通过
- [x] `framework/core/config_service.gd` — 三层合并 `remote > local > defaults`;`load_local` 本地缓存,`apply_remote` 留给 M4;typed getters ✅ 无头验证通过
- [x] `framework/core/time_service.gd` — `now()`/`now_msec()`:服务器锚点 + `Time.get_ticks_msec()` 单调推进;未校时降级为系统时钟且 `is_trusted()` 为 false ✅ 无头验证通过
- [x] Bootstrap 阶段 2 接入:创建 time/config/save,`load_or_create` 含迁移,I/O 失败记 error(应阻断重试);`App` 加 `time/config/save` 字段;切后台 `App._on_app_paused` 已接 `save.flush()` ✅
- [x] 文档:`modules/save-service.md`、`modules/config-service.md`、`modules/time-service.md`;modules 索引更新 ✅

**验收**:写档 → 改版本号 → 读档触发迁移链,日志可见逐级升级;手工损坏存档文件,启动不崩、走兜底;`App.time.now()` 在未校时/已校时两种状态下行为符合文档。

✅ **M2 已完成并通过无头验证**(2026-07-04,18 项断言全过):
- 迁移链:`_run_migrations({orig:1}, 1, 3, {...})` 逐级应用 1→2、2→3,保留原字段
- 存档往返:`set_value` → `flush` → 新实例 `load_or_create` → 字段一致
- 损坏兜底:写入非法 JSON → `load_or_create` 返回 ok(不崩)+ 空档 + `save.corrupt.<时间戳>.json` 备份生成
- 配置合并:remote(300) > local(200) > defaults(100) 优先级正确,缺失键返回 fallback
- 时间:未校时 `is_trusted` false 且 `now` ≈ 系统时钟;`sync_from_server` 后 `is_trusted` true 且 `now` 基于服务器时间
- 键类型统一用 String(JSON 原生键),避免 StringName/String 字典键静默 miss 的坑

## M3 平台防腐层(4~6 天,不含真机联调)

- [x] `platform/platform_provider.gd`(@abstract 共同基类:`initialize()->bool`)+ `platform/ads/ad_provider.gd`(@abstract)+ `ad_result.gd` + `null_ad_provider.gd` + `ad_provider_factory.gd` ✅
- [x] `platform/platform_service.gd` — 聚合门面(`App.platform.ads` / `.analytics`),Node,挂 App 下 ✅ 无头验证通过
- [x] Android / iOS 真实现骨架:`admob_android_provider.gd`、`admob_ios_provider.gd`(initialize 返回 false → 自动降级 Null,真机接入前也能跑)✅
- [x] Analytics 契约 + Null 实现 + 工厂(打点落日志)✅
- [x] Bootstrap 阶段 3 接入:并行初始化(fire-and-forget 协程 + Array 槽)+ 5s 超时 + 失败/超时降级为 Null;`_run` 已 `await` 阶段 3;`App.platform` 字段;`Bus.ad_reward_granted` 信号 ✅
- [x] 文档:`modules/platform-service.md`;modules 索引更新 ✅

**验收**:编辑器 F5 走通"请求激励视频 → Null 模拟观看 1s → `Bus.ad_reward_granted`";强制让 provider 初始化抛错,游戏照常启动且广告入口降级可用。
**注**:真机 SDK 联调(AdMob 等)单独排期,预估每个 SDK 2~4 天,不阻塞后续里程碑。

✅ **M3 已完成并通过无头验证**(2026-07-04,11 项断言全过,不含真机联调):
- 编辑器下 `App.platform.ads` 为 `NullAdProvider`、analytics 为 `NullAnalyticsProvider`
- 发奖流程:`show_rewarded(&"double_coins")` → Null 模拟观看 1s → `is_rewarded()` → 业务 emit `Bus.ad_reward_granted` → 监听方收到
- **降级路径**:强制 `initialize()` 返回 false 的 provider 经 `_init_or_downgrade` 被换成 Null,且降级后 `show_rewarded` 照常发奖
- `AdResult` 值对象语义(rewarded/dismissed/failed+message)正确;`analytics.track` 落日志不崩
- `@abstract` 契约(class + method)在 Godot 4.6.1 编译通过;`AdResult.Status` 自引用枚举已全限定避免级联幻象报错(M1 学到的坑)

## M4 NetworkService(3~4 天)

- [x] `framework/core/network_service.gd` — HTTPRequest 池(`_free_pool` 复用)、超时(`request_timeout`)、指数退避重试(网络层失败/5xx 重试,4xx 不重试)、鉴权头注入(`Authorization: Bearer`)、统一返回 `Result` ✅ 无头验证通过
- [x] `login_and_sync()`:登录 → `App.time.sync_from_server` 校时 → `App.config.apply_remote` 拉配置,一次性握手,任一步失败即降级(不阻断)✅
- [x] Mock 模式:`enable_mock({path: Dictionary|Callable})`,未接后端时 Bootstrap 阶段 4 默认用它演示完整链路 ✅
- [x] 文档:`modules/network-service.md`;modules 索引更新 ✅
- [x] `App.net` 字段;`App._on_app_resumed` 前台恢复时 fire-and-forget 重新握手;Bootstrap 阶段 4 接入 ✅

**验收**:Mock 模式下完成"登录 → 校时 → 拉远程配置"链路;断网状态下所有请求正确超时并返回 err,游戏不卡死。

✅ **M4 已完成并通过无头验证**(2026-07-04,9 项断言全过):
- Mock 完整握手:`login_and_sync()` → token 写入、`TimeService.is_trusted()` 变真且 `now()` 取服务器时间、`ConfigService` 拿到 remote 值
- Mock 缺失 path / 自定义 Callable 失败分支均返回 `err`,不崩
- **真实网络路径**:请求不可路由地址(`request_timeout=0.5s, max_retries=1`),实测 ~1.1s 内返回 `err`,未卡死,验证"断网不挂起"
- 4xx 不重试、5xx/网络层失败按指数退避重试,是有意的区分(重试 4xx 无意义,见 network-service.md)

## M5 音频与资产(3~4 天)

- [x] `framework/managers/audio_service.gd` — BGM/SFX 程序化总线 + 线性音量、双播放器交叉淡变(同曲不打断)、SFX 池;kill-tween 消除快速连切竞态 ✅ 无头验证通过
- [x] `framework/managers/asset_service.gd` — `asset_map.tres`(id → 路径 + 分组)、`preload_group`/`release_group`、`get_asset`、`AssetIds` 常量类;`AssetMap`/`AssetMapEntry` 脚本 + `ResPaths.ASSET_MAP` ✅ 无头验证通过
- [x] Bootstrap 阶段 5 预热 `&"core"` 组;SceneService 按 `SceneRegistryEntry.asset_group` 切场景时预载新组/释放旧组(空组跳过,行为同 M1)✅ 无头验证通过
- [x] 文档:`modules/audio-service.md`、`modules/asset-service.md`;modules 索引更新 ✅

**验收**:切场景 BGM 平滑过渡不中断;监视内存,离开场景后其资产组确实被释放。

✅ **M5 已完成并通过无头验证**(2026-07-04,音频/资产 12 项 + 场景集成 6 项):
- 音频:BGM/SFX 总线程序化创建、音量 set/get 往返、交叉淡变切曲后 active 播放器持有新曲且在播、同曲不 flip(不打断)、SFX 池轮转
- 资产:core 组启动预热、`get_asset` 缓存命中、未知 id 返回 null、**release 后资源被引擎回收(WeakRef 变空)**
- 场景集成:进 level 预载 level 组、回 main_menu 释放 level 组、core 组始终保留
- **踩坑**:`current_id` 在切换中途(change_scene 时)就更新,而 `scene_changed` 在淡入结束才发——"切换真正完成"必须以 `scene_changed` 为准,不能靠 `current_id`。测试改用"从最早期数 scene_changed 完成次数"才稳定(否则会 catch 到上一次切换的滞后 emit)
- **音频竞态**:快速连切 BGM 时旧淡变的 fire-and-forget 收尾 `stop()` 会误杀新曲;改为存 tween、新切换先 kill 旧 tween、用 `tween_callback` 代替 `await`(kill 时 callback 不触发)彻底消除

## M6 质量收口(3~5 天)

- [x] `tools/check_architecture.gd` — 实现 [directory.md](../conventions/directory.md) 违规引用清单检查(framework→game/platform、change_scene 越界、裸 assets 路径),退出码=违规数;`tools/README.md` 附 pre-commit 接入方式 ✅ 无头验证通过(含故意埋雷)
- [x] 调试面板 `game/ui/debug_panel.gd`(Debug 层,KEEP 缓存):FPS/内存、场景跳转、存档清除(`SaveService.wipe`)/导出(`to_json`)、Bus 事件监视;注册 `UIIds.DEBUG` ✅
- [x] 无头单测 `tools/tests/`(不依赖 gdUnit4,零依赖 CI 就绪):Result / SaveService 迁移 / ConfigService 合并 / TimeService 偏移,22 断言 + 哨兵防假绿 ✅ 全绿 exit 0
- [x] 全流程 Demo:`main_menu` 改为演示中枢(进关卡/设置/看广告发奖存档/调试面板 + 金币持久化),`level` 加返回按钮 ✅ 无头验证通过
- [x] 文档:所有模块文档 `active`,modules 索引齐全;新增 `tools/README.md` ✅

**验收**:检查脚本对故意埋的违规引用能报错;单测全绿可无头运行(CI 就绪);Demo 全流程 10 分钟内可向他人演示。

✅ **M6 已完成并通过无头验证**(2026-07-04):
- 架构检查器:干净代码 CLEAN(扫 45 文件);故意在 framework 埋 `res://src/game/` 引用 + `change_scene` → 精确报 2 处违规,exit 2
- 单测:22 断言全绿 exit 0。**踩坑**:`--script` 模式不加载 autoload,凡在文件作用域引用 App 的类(SaveService/ConfigService)会编译失败;改为以主场景 `test_runner.tscn` 启动(autoload 随任意主场景加载),测试只调不碰 App 的纯逻辑方法。哨兵 `_EXPECTED_CHECKS` 防止某测试方法中途抛错被静默跳过而假绿
- Demo 全流程 12 断言:清档→看广告(Null 模拟)→金币+10→flush→新 SaveService 读盘仍为 10→再看累加到 20→调试面板开关→设置弹窗开+返回键关→关卡往返
- 至此 M0~M6 全部完成,App 挂齐 log/scenes/ui/time/config/save/platform/net/audio/assets 十项服务

## M7 注册表代码生成(半天)

- [x] 三份注册表 .tres 改为**直接拖资源引用**(PackedScene/Resource,UID 追踪抗改名移动),id 默认取文件名 + `id_override` 兜底(asset_map 同文件多组、ui 短名都靠它)✅
- [x] `tools/registry_codegen.gd` + 无头入口 `generate_registries.tscn`(`-- check` 供 CI 校验生成物过期)+ 编辑器一键 `editor_regen_registries.gd`(File > Run)✅
- [x] 生成 `src/resource/generated/` 下 `Scenes`/`Uis`/`Assets` 强类型常量类,加载键用 **uid://**(改名/移动后不重新生成也不断链);删除手写 `SceneIds`/`UIIds`/`AssetIds`/`ResPaths` ✅
- [x] 三个 Service 运行时零 .tres 加载(查表纯静态);单测新增 4 项注册表校验(26 断言);文档同步(naming/add-a-ui/模块文档/tools README)✅ 无头验证通过(codegen check + 架构 CLEAN + 26 测试 + 启动冒烟全绿)

**设计要点**:注册表 .tres 是唯一权威数据源(策划侧拖拽编辑),常量类是它的编译产物——"双数据源失配"靠生成关系消解,不靠人肉对齐。生成器对 id 重复/非法、条目漏拖资源报错拒绝生成,对场景 asset_group 无对应资产告警。

## 启动管线重构(2026-07-06)

- [x] `core/boot/` — `BootPipeline` + `StageRunner` + 8 个 `BootStage`(Log / CoreServices / LocalConfig / Save / Platform / Network / Asset / EnterGame);`bootstrap.gd` 瘦身为入口 ✅
- [x] 文档同步:`architecture/boot-sequence.md`、各 `modules/*-service.md`、`guides/add-a-service.md` ✅

---

## 迁移轨道(现有项目,与 M2+ 并行)

M1 完成、API 趋稳后即可启动,方法论见架构讨论(绞杀者模式):

1. **立法**(M1 后立即):现有项目新代码禁止旧写法
2. **包壳**:旧全局单例用 `App.xxx` facade 包一层,实现不动
3. **按 git 改动频率排序迁移**:最常改的模块最先迁(通常是 UI)
4. **迁一杀一**:迁完立刻删旧入口,禁止双轨并存
5. **上检查脚本**(M6 的脚本可提前用):机械化守住架构

迁移工作量取决于现有项目规模,启动时单独评估,**不计入上表**。

## 风险与对策

| 风险 | 对策 |
|---|---|
| 真机 SDK 联调时间不可控 | Null 实现先行,真机联调独立排期,不阻塞主线 |
| 框架越写越大,迟迟不能回去做游戏 | 每个服务只做验收标准要求的最小集,想加的功能记 TODO 不实现(YAGNI) |
| 单人同时维护新框架 + 旧项目,上下文切换损耗 | 按里程碑整块推进,不要两边每天各改一点 |
| API 设计返工 | M1 完成后先在 Demo 里"吃自己的狗粮"再启动迁移,发现别扭立刻改——此时改 API 成本最低 |
