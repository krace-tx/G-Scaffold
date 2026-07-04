# 框架开发计划

> status: active | 最后更新: 2026-07-04 | 预估基准:1 名开发者全职;真机 SDK 联调不计入

## 总目标

在 g-scaffold 中实现框架内核与全部基础服务,达到两个"完成"标准:

1. **新游戏可直接以此为起点**:F5 能跑通"启动 → 主菜单 → 进关卡 → 弹窗 → 看广告(Null)→ 发奖 → 存档"的完整演示流程。
2. **现有项目可开始绞杀者迁移**:框架 API 稳定,迁移轨道(见下)可启动。

## 里程碑总览

| 里程碑 | 内容 | 预估 | 前置 | 状态 |
|---|---|---|---|---|
| M0 | 内核四件套:App / Bus / LogService / Bootstrap | 2~3 天 | — | ✅ 已完成 |
| M1 | SceneService + UIService(场景与 UI 生命周期) | 4~6 天 | M0 | ✅ 已完成 |
| M2 | SaveService + ConfigService + TimeService(数据层) | 3~4 天 | M0 | ⬜ 未开始 |
| M3 | 平台防腐层:契约 + Null 全家桶 + Android/iOS 骨架 | 4~6 天 | M0 | ⬜ 未开始 |
| M4 | NetworkService(传输层) | 3~4 天 | M0, M2 | ⬜ 未开始 |
| M5 | AudioService + AssetService | 3~4 天 | M0 | ⬜ 未开始 |
| M6 | 质量收口:检查脚本、调试面板、单测、全流程 Demo | 3~5 天 | M1~M5 | ⬜ 未开始 |

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

- [ ] `framework/core/save_service.gd` — 版本化 JSON(见 [ADR-0003](../architecture/decisions/0003-versioned-json-saves.md))、迁移表、`flush()`、损坏档兜底(备份 + 报告)
- [ ] `framework/core/config_service.gd` — 三层合并:代码默认值 ← 本地缓存 ← 远程覆盖(远程拉取本期留接口,M4 接通)
- [ ] `framework/core/time_service.gd` — `now()`:服务器时间戳 + `Time.get_ticks_msec()` 偏移;未校时前的降级策略(标记不可信)
- [ ] Bootstrap 阶段 2 接入:加载存档含迁移,失败阻断重试
- [ ] 文档:`modules/save-service.md`、`modules/config-service.md`、`modules/time-service.md`

**验收**:写档 → 改版本号 → 读档触发迁移链,日志可见逐级升级;手工损坏存档文件,启动不崩、走兜底;`App.time.now()` 在未校时/已校时两种状态下行为符合文档。

## M3 平台防腐层(4~6 天,不含真机联调)

- [ ] `platform/ads/ad_provider.gd`(@abstract)+ `ad_result.gd` + `null_ad_provider.gd` + 工厂
- [ ] `platform/platform_service.gd` — 聚合门面(`App.platform.ads` 等)
- [ ] Android / iOS 真实现**骨架**(接口占位 + TODO,SDK 接入时填充)
- [ ] Analytics 契约 + Null 实现(打点先落日志)
- [ ] Bootstrap 阶段 3 接入:并行初始化 + 5s 超时 + 失败降级为 Null
- [ ] 文档:`modules/platform-service.md`

**验收**:编辑器 F5 走通"请求激励视频 → Null 模拟观看 1s → `Bus.ad_reward_granted`";强制让 provider 初始化抛错,游戏照常启动且广告入口降级可用。
**注**:真机 SDK 联调(AdMob 等)单独排期,预估每个 SDK 2~4 天,不阻塞后续里程碑。

## M4 NetworkService(3~4 天)

- [ ] `framework/core/network_service.gd` — HTTPRequest 池、超时、指数退避重试、鉴权头注入、统一返回 `Result`
- [ ] 登录/校时握手流程(接通 TimeService 与 ConfigService 的远程层)
- [ ] 无后端环境的 Mock 模式(本地 JSON 应答,编辑器可跑)
- [ ] 文档:`modules/network-service.md`

**验收**:Mock 模式下完成"登录 → 校时 → 拉远程配置"链路;断网状态下所有请求正确超时并返回 err,游戏不卡死。

## M5 音频与资产(3~4 天)

- [ ] `framework/managers/audio_service.gd` — BGM/SFX 总线分组音量、BGM 跨场景淡入淡出、SFX 播放器池
- [ ] `framework/managers/asset_service.gd` — `asset_map.tres`(id → 路径 + 分组)、按组预载/释放、`AssetIds` 常量类
- [ ] Bootstrap 阶段 5 接入核心资产预热;SceneService 切场景时按组预载/释放
- [ ] 文档:`modules/audio-service.md`、`modules/asset-service.md`

**验收**:切场景 BGM 平滑过渡不中断;监视内存,离开场景后其资产组确实被释放。

## M6 质量收口(3~5 天)

- [ ] `tools/check_architecture.gd`(或 shell 脚本)— 实现 [directory.md](../conventions/directory.md) 的违规引用清单检查,接入 pre-commit
- [ ] 调试面板(Debug 层 UI):场景跳转、日志查看、Bus 事件监视、存档清除/导出、FPS/内存
- [ ] gdUnit4 单测:Result / SaveService 迁移 / ConfigService 合并 / TimeService 偏移 等纯逻辑路径
- [ ] 全流程 Demo 打磨:启动 → 主菜单 → 关卡 → 弹窗 → 看广告(Null)→ 发奖 → 存档 → 重启验证
- [ ] 文档全面复查:所有模块文档转 `active`,README 索引更新

**验收**:检查脚本对故意埋的违规引用能报错;单测全绿可无头运行(CI 就绪);Demo 全流程 10 分钟内可向他人演示。

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
