# 目录结构与归属规范

> status: active | 最后更新: 2026-07-04

## 目录归属表

| 目录 | 放什么 | 明确不放什么 |
|---|---|---|
| `src/framework/autoloads/` | **仅** `app.gd` 与 `bus.gd` | 任何服务实现(见 ADR-0001) |
| `src/framework/core/` | 无场景树依赖的服务与基建:Bootstrap、LogService、TimeService、ConfigService、SaveService、NetworkService、utils、Result 等基础类型 | 需要挂在场景树上的东西 |
| `src/framework/managers/` | 场景树/呈现相关服务:SceneService、UIService、AudioService、AssetService、BaseScene、BaseUI | 业务逻辑 |
| `src/platform/ads/` | 广告契约(`AdProvider`)、各 SDK 实现、Null 实现、工厂 | 广告奖励的业务发放逻辑(放 game/) |
| `src/platform/android/`、`ios/` | 系统功能桥接(JNI/插件封装) | 与平台无关的代码 |
| `src/game/entities/` | 玩家、敌人等实体及其组件 | — |
| `src/game/scenes/` | 关卡与主场景(.tscn + 同名脚本) | — |
| `src/game/ui/` | UI 预制体(.tscn + 同名脚本) | 通用 UI 框架(放 framework/managers) |
| `src/assets/` | 纯媒体文件(audio/fonts/models/textures) | 任何 .gd / .tscn / .tres |
| `src/resource/scripts/` | 自定义 Resource 类定义 | — |
| `src/resource/data/` | .tres 配置实例、JSON/CSV 静态数据、统一资源清单(asset_manifest) | 玩家存档(在 user://) |
| `docs/` | 全部文档(.gdignore,编辑器不可见) | — |
| `addons/` | 第三方引擎插件;**及自研的编辑器专用插件**(见下方例外) | 运行时代码(会被 src/ 引用或打进游戏包的) |

## 新文件放哪 —— 决策清单

依次自问:

1. 是媒体文件? → `assets/` 对应子目录
2. 是配置数据或 Resource 类? → `resource/data/` 或 `resource/scripts/`
3. 调用了第三方 SDK 或平台 API? → `platform/`
4. 换一个游戏还能直接用? → `framework/`(无场景树依赖进 `core/`,有则进 `managers/`)
5. 其余一律 → `game/`

**拿不准时放 `game/`。** 从 game 提升到 framework 容易,反向下沉很痛苦。

### 例外:自研的编辑器专用插件放 `addons/`

`addons/` 原则上只放第三方插件,但**编辑器工具是唯一例外**:Godot 硬性要求 `EditorPlugin`
(`plugin.cfg` + 入口脚本)必须落在 `addons/<name>/` 下才会被引擎识别,没有第二选择。
这类代码只在编辑器里运行,不被 `src/` 引用、不打进游戏包,因此不违反单向依赖。判定标准:
**脚本带 `@tool` 且依赖 `Editor*` 类(EditorPlugin / EditorFileDialog / EditorInterface)= 编辑器工具 → `addons/`。**
现有例子:`addons/asset_groups/`(资源清单可视化编辑器,见 [asset-groups.md](../modules/asset-groups.md))。

## 违规引用清单(可脚本化检查)

以下 grep 命中即为架构违规,Review 直接打回:

| 检查范围 | 禁止出现 |
|---|---|
| `src/framework/**` | `res://src/game/`、`res://src/platform/` |
| `src/platform/**` | `res://src/game/` |
| `src/game/**` | SDK 类名直接调用、`Engine.get_singleton(`(经 platform/ 门面) |
| 全项目(除清单) | 裸 `res://src/assets/` 路径字符串(经 AssetService + asset_manifest) |
| 全项目 | `get_tree().change_scene`(仅 SceneService 内部允许) |
