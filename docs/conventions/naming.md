# 命名规范

> status: active | 最后更新: 2026-07-04

## 文件与节点

| 对象 | 规则 | 示例 |
|---|---|---|
| 脚本/场景/资源文件 | snake_case | `scene_service.gd`、`main_menu.tscn` |
| 场景与其脚本 | 同名配对 | `main_menu.tscn` + `main_menu.gd` |
| 节点名 | PascalCase | `HealthBar`、`AdRewardPopup` |

## 类与类型

| 对象 | 规则 | 示例 |
|---|---|---|
| 类名(class_name) | PascalCase,所有可复用类必须声明 | `SaveService` |
| 框架服务 | `XxxService` 后缀 | `AudioService` |
| 平台提供者契约 | `XxxProvider` 后缀(@abstract) | `AdProvider` |
| 提供者实现 | `厂商/平台 + 契约名` | `AdmobAndroidProvider`、`NullAdProvider` |
| 业务服务(game/) | `XxxService` 后缀 | `RankService` |

## 信号

| 场景 | 规则 | 示例 |
|---|---|---|
| Bus 领域事件 | **过去式**,禁止 `*_requested` | `purchase_completed`、`player_died` |
| 节点自身信号 | 过去式或状态变化 | `died`、`value_changed` |

## 常量与标识符

| 对象 | 规则 | 示例 |
|---|---|---|
| 常量 | SCREAMING_SNAKE_CASE | `MAX_RETRY_COUNT` |
| 变量/函数 | snake_case;私有加 `_` 前缀 | `_retry_count` |
| 场景 id | 集中在 `SceneIds` 常量类 | `SceneIds.MAIN_MENU` |
| UI id | 集中在 `UIIds` 常量类 | `UIIds.SETTINGS` |
| 资产 id | 集中在 `AssetIds` 常量类(由清单导出生成) | `AssetIds.BTN_CLICK_SFX` |
| **框架资源文件路径** | 集中在 `ResPaths` 常量类 | `ResPaths.MANIFEST` |
| StringName 字面量 | 用 `&"xxx"` 形式 | `&"fade"` |

**原则:同一个字符串在两处以上出现,必须提升为常量。** 魔法字符串是重构的头号敌人。

### ID 常量 vs 路径常量:两类不要混

- **ID 常量类**(`SceneIds` / `UIIds` / `AssetIds`)存的是**逻辑标识**——业务代码用它表达"我要哪个场景/界面/资产",不关心它在磁盘哪。这三份文件由 Asset Groups 编辑器插件从清单**导出时整体生成**,不要手改(见 [asset-groups.md](../modules/asset-groups.md))。
- **`ResPaths`** 存的是框架硬编码的**物理文件路径**——统一清单/配置 `.tres` 的 `res://` 位置(如 `asset_manifest.tres`),供框架内部 `load()` 用。

判断口诀:**"我要哪个东西" → ID 常量;"这个文件在哪" → `ResPaths`。** 禁止在 Service 里再写 `const _XXX_PATH := "res://..."` 局部常量。

## Autoload

只有 `App` 与 `Bus` 两个,禁止新增(见 [ADR-0001](../architecture/decisions/0001-typed-app-root.md))。
