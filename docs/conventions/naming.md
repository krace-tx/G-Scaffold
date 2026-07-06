# 命名规范

> status: active | 最后更新: 2026-07-05

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
| 场景 id | 生成的 `Scenes` 常量类(勿手写,见下) | `Scenes.MAIN_MENU` |
| UI id | 生成的 `Uis` 常量类(勿手写,见下) | `Uis.SETTINGS` |
| 资产 id | 生成的 `Assets` 常量类(勿手写,见下) | `Assets.BTN_CLICK_SFX` |
| StringName 字面量 | 用 `&"xxx"` 形式 | `&"fade"` |

**原则:同一个字符串在两处以上出现,必须提升为常量。** 魔法字符串是重构的头号敌人。

### ID 常量类与注册表保持同步

`Scenes` / `Uis` / `Assets`(`src/resource/generated/`)对应三份注册表 .tres
(scene_registry / ui_registry / asset_map):注册表(Inspector 里拖资源登记)是
**唯一权威数据源**,常量类需与注册表手动保持同步。改了注册表就同步改
`src/resource/generated/` 下对应的 `Scenes` / `Uis` / `Assets` 文件。

- 业务代码只认 `Scenes.XXX` / `Uis.XXX` / `Assets.XXX`,禁止裸字符串 id。
- 运行时不 load 注册表 .tres(条目直接引用资源本体,load 会全量进内存);查表一律
  走生成类,生成类里存 uid:// 加载键,文件移动/改名不断链。
- 禁止在 Service 里写 `const _XXX_PATH := "res://..."` 局部常量——`res://` 路径只应
  出现在注册表 .tres 与生成类里。

## Autoload

只有 `App` 与 `Bus` 两个,禁止新增(见 [ADR-0001](../architecture/decisions/0001-typed-app-root.md))。
