# G-Scaffold (Godot 4.x Enterprise Game Scaffold)

<div align="center">

![Godot Engine](https://img.shields.io/badge/Godot_Engine-v4.4+-478CBF?logo=godotengine&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Desktop-green)
![License](https://img.shields.io/badge/License-MIT-blue)
![Architecture](https://img.shields.io/badge/Architecture-Service_Locator_%2B_Boot_Pipeline-orange)

**专为商业级手游与独立游戏打造的 Godot 4.x 高性能、纯通用、开箱即用的工程底座架构模板。**

[架构概览](#核心架构体系) •
[服务体系](#11-大核心单例服务) •
[快速开始](#快速开始) •
[目录规范](#标准目录规范) •
[文档地图](#文档地图)

</div>

---

## 核心特性

- **三层解耦设计**：`Framework`（通用纯底座）➔ `Game/Core`（业务中枢）➔ `Scenes`（纯视图与交互），杜绝跨层强耦合与内存泄露；
- **渐进式启动管线 (Boot Pipeline)**：支持 Stage 阶段编排、异步并行加载、冷启动耗时诊断与故障自愈降级；
- **5 档环境与路由流转**：`LOCAL` ➔ `EMULATOR (10.0.2.2)` ➔ `DEV` ➔ `TEST` ➔ `PROD` 细分体系，自动分流 API 域名；
- **11 大核心基础服务**：集中由全局单例 `App` 统一托管（网络池、多级缓存持久化、权威时钟、多语言、场景栈、音效管理等）；
- **全套商业级原生插件集成**：内置 Google AdMob、Google Play / App Store IAP、Apple Sign-In、Google Sign-In、iOS ATT 隐私授权与原生分享；
- **完整单元测试套件**：内置 `src/test/` 自动化测试管线，支持网络、存储、实体编解码等全套用例；
- **Agent 图谱与上下文感知**：深度集成 `.agents/` 知识库与规范 Skills，AI 辅助编码零污染。

---

## 核心架构体系

```text
                           ┌────────────────────────┐
                           │      Global App        │  (Autoload / Service Locator)
                           └───────────┬────────────┘
                                       │
         ┌─────────────────────────────┼─────────────────────────────┐
         ▼                             ▼                             ▼
┌──────────────────┐          ┌──────────────────┐          ┌──────────────────┐
│   Core Services  │          │   Infra Layer    │          │  Boot Pipeline   │
│  - App.net       │          │  - BaseScene     │          │  - BootStage     │
│  - App.persist   │          │  - BaseUI        │          │  - ProgressAnim  │
│  - App.audio     │          │  - BaseParams    │          │  - ErrorHandling │
│  - App.locale... │          │  - SceneStack    │          │  - Fast Recovery │
└──────────────────┘          └──────────────────┘          └──────────────────┘
```

---

## 11 大核心单例服务 (`App.*`)

| 服务单例 | 功能与职责 |
| :--- | :--- |
| **`App.env`** | 5 档环境探测与 Feature Tag 判定（`LOCAL`, `EMULATOR`, `DEV`, `TEST`, `PROD`） |
| **`App.log`** | 结构化终端诊断日志（支持 DEBUG / INFO / WARN / ERROR 级别过滤与时间戳） |
| **`App.net`** | HTTP 连接池管理、重试容灾与自动 Token 鉴权注入 |
| **`App.persist`** | 内存与本地磁盘二级缓存持久化，支持强类型 `Resource` 编解码 |
| **`App.time`** | 远端权威时间戳同步与防单机时间作弊校准 |
| **`App.locale`** | 多语言国际化运行时动态切换与 CSV 自动解析映射 |
| **`App.asset`** | 运行时三级资产加载池与弱引用内存释放管理 |
| **`App.scene`** | 场景栈式导航（`push` / `pop` / `replace`）与安全黑屏转场遮罩 |
| **`App.audio`** | 全局音效分组播放、静音控制与 BGM 无缝无限循环保证 |

---

## 标准目录规范

```text
g-scaffold/
├── .agents/                   # AI Agent 图谱与能力知识库 (Skills)
├── addons/                    # 原生第三方插件库 (AdMob, IAP, Apple, Google, ATT, Share)
├── docs/                      # 架构设计与平台环境文档
├── src/
│   ├── assets/                # 原始资产 (Textures, Audio, Fonts, Translations)
│   │   ├── textures/          # 通用贴图素材 (.gitkeep 规范骨架)
│   │   ├── audio/             # 背景音乐与按钮音效 (.gitkeep)
│   │   ├── fonts/             # 通用标准字体 (Roboto)
│   │   └── translations/      # 多语言翻译表 (i18n.csv)
│   │
│   ├── framework/             # 纯通用框架层 (100% 纯净与业务无关)
│   │   ├── autoloads/         # 全局单例 (App, Bus)
│   │   ├── core/              # 11 大服务、Boot 管线、工具函数库 (Utils)
│   │   └── infra/             # UI/Scene/Params 基础设施
│   │
│   ├── game/                  # 游戏业务层
│   │   ├── autoloads/         # 业务全局聚合根 (Game)
│   │   ├── catalog/           # 路由、常量与清单路由表 (Scene/Popup/Audio/Api Catalog)
│   │   ├── core/              # 核心管理器 (SettingManager, ConfigManager, ProfileManager)
│   │   ├── entities/          # 强类型纯数据实体 (UserProfile, GameConfig, GameSetting)
│   │   └── scenes/            # 场景与 UI 视图
│   │       ├── launcher/      # 引导启动场景 (演示 BootPipeline 与加载动效)
│   │       ├── example/       # 演示主场景 (演示场景流转、音频、设置弹窗与 Toast)
│   │       └── common/popup/  # 通用设置弹窗 (ExampleSetting) 与轻量 Toast
│   │
│   ├── resource/              # 引擎内置材质与 Shader 骨架 (.gitkeep)
│   └── test/                  # 自动化单元测试套件体系 (Test Suites)
│
├── export_presets.cfg         # Android 4 档环境导出预设配置
└── project.godot              # Godot 项目总配置
```

---

## 快速开始

### 1. 克隆项目
```bash
git clone https://github.com/krace-tx/G-Scaffold.git
```

### 2. 导入与运行
1. 使用 **Godot 4.3+ / 4.4+** 打开本项目；
2. 直接点击 `F5`（运行项目），将自动从 `src/game/scenes/launcher/launcher.tscn` 启动；
3. 观察控制台日志输出启动流水线耗时，进入 `ExampleScene` 演示主场景，体验音效、设置切换与 Toast 提示。

### 3. 基于脚手架开发新业务
1. **多语言**：在 `src/assets/translations/i18n.csv` 中追加新词条；
2. **新增场景**：继承 `BaseScene` 并在 `src/game/catalog/scene_catalog.gd` 注册路径；
3. **新增数据实体**：继承 `Resource`，使用 `ResourceCodecUtils` 配合实现 `encode()` / `decode()`；
4. **数据持久化**：使用 `App.persist.save_async()` 与 `App.persist.read_async()` 一键读写。

---

## 文档地图

项目采用就近文档架构，每个关键模块均内置有专属说明：

- **Android 打包与环境搭建**：[docs/_doc_android_environment.md](docs/_doc_android_environment.md)
- **框架核心底座架构**：[src/framework/_doc_framework.md](src/framework/_doc_framework.md)
- **11 大服务调用指南**：[src/framework/core/services/_doc_services.md](src/framework/core/services/_doc_services.md)
- **UI 基础设施与规范**：[src/framework/infra/ui/_doc_ui.md](src/framework/infra/ui/_doc_ui.md)
- **场景栈流转与生命周期**：[src/framework/infra/scene/_doc_scene.md](src/framework/infra/scene/_doc_scene.md)
- **多语言国际化规范**：[src/framework/core/services/locale_service/_doc_locale_service.md](src/framework/core/services/locale_service/_doc_locale_service.md)

---

## License

Distributed under the MIT License. See `LICENSE` for more information.
