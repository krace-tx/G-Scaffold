# Asset Groups

> 编辑器专用插件 · 不参与运行时打包 · 类比 Unity Addressables Group

在 Godot 底部面板 **Asset Groups** 里，用可视化方式登记 **场景 / UI / 资产**，按分组管理内存预载策略，一键生成框架运行时所需的注册表与 id 常量。

---

## 30 秒理解

| 问题 | 答案 |
|---|---|
| 解决什么 | 集中管理 `id → 资源路径` 映射，以及资产的 **分组预载/释放** |
| 唯一真源 | `src/resource/data/asset_manifest.tres`（编辑态清单） |
| 怎么用 | 在 Dock 里编辑 → 点 **Generate All** |
| 运行时谁消费 | `SceneService` / `UIService` / `AssetService`，通过生成的查表类访问，**不 load 注册表 .tres** |

```
编辑 manifest.tres  →  Generate  →  三份 .tres 注册表 + id 常量脚本
											  ↓
							  Scenes / Uis / Assets（框架查表类，待/codegen 衔接）
											  ↓
						 SceneService / UIService / AssetService
```

---

## 目录结构

```
addons/asset_groups/
├── plugin.gd / plugin.cfg     # 插件入口，挂到底部面板
├── README.md                  # 本文档
│
├── dock/                      # UI 层（只改 manifest，不管代码生成细节）
│   ├── asset_group_dock.*     # 根面板：加载/保存 manifest、Generate All
│   ├── scene_group_panel.*    # Scenes 页：场景 id + 路径 + 关联资产组
│   ├── ui_group_panel.*       # UI 页：界面 id + 路径 + 层级 + 缓存策略
│   ├── asset_group_panel.*    # Assets 页：分组树 + 资产 id + 路径
│   ├── asset_group_tree.gd    # 分组树拖拽（哑组件，只发 reassign 信号）
│   └── asset_groups_style.gd  # 编辑器样式
│
├── entities/                  # 数据模型（Resource 脚本）
│   ├── manifest/              # 编辑态
│   │   ├── asset_manifest.gd  # 根清单 + 分组管理 API
│   │   ├── scene_entry.gd
│   │   ├── ui_entry.gd
│   │   └── asset_entry.gd
│   ├── scene/                 # 运行时 → SceneService
│   │   ├── scene_registry.gd
│   │   └── scene_registry_entry.gd
│   ├── ui/                    # 运行时 → UIService
│   │   ├── ui_registry.gd
│   │   └── ui_registry_entry.gd
│   └── asset/                 # 运行时 → AssetService
│       ├── asset_map.gd
│       └── asset_map_entry.gd
│
└── generator/                 # 生成管线
	├── manifest_validator.gd  # Generate 前校验（硬错误 / 软警告）
	├── manifest_scanner.gd    # 扫描目录 → 追加 manifest 条目
	├── manifest_entries.gd    # 筛完整条目 / 草稿跳过
	├── generator_utils.gd     # 目录创建、UID 解析
	├── accessors_generator.gd # manifest → Scenes / Uis / Assets
	├── registry_generator.gd  # manifest → 三份 .tres
	└── ids_generator.gd       # manifest → SceneIds / UIIds / AssetIds
```

---

## 两层数据模型

### 1. 编辑态（Manifest）— Dock 读写的唯一真源

持久化文件：`res://src/resource/data/asset_manifest.tres`

| 类型 | 字段 | 说明 |
|---|---|---|
| `AssetManifest` | `scenes`, `uis`, `assets`, `groups` | 根资源，三页共享同一实例 |
| `SceneEntry` | `id`, `scene_path`, `asset_group` | 顶层场景；`asset_group` 决定切场景时预载哪组资产 |
| `UIEntry` | `id`, `scene_path`, `layer`, `cache` | 界面；层级与缓存策略供 UIService 使用 |
| `AssetEntry` | `id`, `path`, `group` | 任意资源文件；`group` 是预载/释放的单位 |

`AssetManifest` 还提供分组相关 API：

- `collect_groups()` — 合并显式分组 + 资产引用的组名
- `add_group` / `remove_group` / `rename_group` — 仅在 Assets 页管理分组
- `find_scene` / `find_ui` / `find_asset` / `assets_in_group`

默认存在 `core` 分组（常驻资产，Boot 时预热，永不释放）。

### 2. 运行时（Registry）— Generate 产物，对接框架 Service

Generate 时由 `RegistryGenerator` **全量重建、整份覆盖**，不做增量 merge。

| 注册表 | 条目字段 | 消费方 |
|---|---|---|
| `SceneRegistry` | `id`, `scene_path`, `asset_group` | `SceneService` → `Scenes.xxx()` |
| `UIRegistry` | `id`, `scene_path`, `layer`, `cache` | `UIService` → `Uis.xxx()` |
| `AssetMap` | `id`, `path`, `group` | `AssetService` → `Assets.xxx()` |

**为何存路径字符串而非 PackedScene 引用？**  
注册表 .tres 若直接引用资源本体，`load` 时会把所有条目同步拉进内存。运行时 Service 只读生成的查表类（含 `uid://` 加载键），按需加载。

`UIEntry.Layer/Cache` 与 `UIRegistryEntry.Layer/Cache` **枚举按序对齐**（HUD < WINDOW < … < DEBUG），生成器经 `int()` 转换。

---

## 编辑器工作流

### 打开面板

启用插件后，编辑器底部 **Asset Groups** 标签页。

### 三个 Tab 的分工

| Tab | 做什么 | 分组权限 |
|---|---|---|
| **Scenes** | 登记顶层场景，选择关联 `asset_group` | 只读下拉（从 manifest 读组名） |
| **UI** | 登记界面，选 Layer / Cache | 无 |
| **Assets** | 按分组树管理资产，支持拖拽换组 | **唯一** 可新建/重命名/删除分组 |

Scenes 页引用了一个不存在的分组？在 Assets 页新建即可；空组也会保留在 `groups` 数组里。

### 顶层按钮

| 按钮 | 行为 |
|---|---|
| **Reload** | 从磁盘重载 `asset_manifest.tres`，丢弃未保存编辑 |
| **Scan import** | 扫描 `src/game/scenes`、`src/game/ui`、`src/assets`，追加尚未登记的资源（id = 文件名，无分组，路径已存在则跳过） |
| **Generate All** | 校验 → 写注册表 .tres → 写 id 常量 → 刷新文件系统 |

任意子面板编辑后，Dock 自动 **保存 manifest + 刷新三页**（orchestrator 模式：子面板只 `emit changed`，根面板统一存盘）。

---

## Generate 管线

```
Generate All
	│
	├─ ManifestValidator.hard_errors()     ← 仅校验完整条目;空 manifest 可通过
	│
	├─ RegistryGenerator.generate_and_save()
	│     → scene_registry.tres / ui_registry.tres / asset_map.tres
	│
	├─ AccessorsGenerator.generate_and_save()
	│     → src/resource/generated/scenes.gd  (Scenes)
	│     → src/resource/generated/uis.gd     (Uis)
	│     → src/resource/generated/assets.gd  (Assets)
	│
	├─ IdsGenerator.generate_and_save()
	│     → scene_ids.gd / ui_ids.gd / asset_ids.gd
	│
	└─ ManifestValidator.soft_warnings()     ← 草稿跳过 / 分组引用,仅提示
```

**空 manifest 也可 Generate**：会写出空的 `_TABLE` / `_GROUPS` 模板，`SceneService` / `UIService` / `AssetService` 可正常编译运行。业务代码里的 `Scenes.MAIN_MENU` 等常量需 Scan import 或手动登记后再 Generate 才有。

### 硬错误（阻断 Generate）

- 某类型内 `id` 为空或重复
- `scene_path` / `path` 为空
- id 不是合法标识符，或转大写后常量名冲突（IdsGenerator）

### 软警告（不阻断）

- 场景引用的 `asset_group` 下没有任何资产
- 某分组（除 `core`）没有被任何场景引用 → 该组资产不会被预载

---

## 生成物与路径

| 产物 | 路径 | 用途 |
|---|---|---|
| 编辑态清单 | `src/resource/data/asset_manifest.tres` | Dock 读写的唯一真源 |
| 场景注册表 | `src/resource/data/scene_registry.tres` | RegistryGenerator 写入 |
| UI 注册表 | `src/resource/data/ui_registry.tres` | RegistryGenerator 写入 |
| 资产注册表 | `src/resource/data/asset_map.tres` | RegistryGenerator 写入 |
| id 常量 | `src/resource/scripts/scene_ids.gd` 等 | `SceneIds.MAIN_MENU` 形式，禁止裸字符串 |
| 查表类 | `src/resource/generated/scenes.gd` 等 | `Scenes` / `Uis` / `Assets`，框架 Service 直接引用 |
| id 常量 | `src/resource/scripts/scene_ids.gd` 等 | `SceneIds` / `UIIds` / `AssetIds`（可选辅助） |

> **注意**：查表类由 `AccessorsGenerator` 自动生成，加载键用 **uid://**（文件移动/改名不断链）。

---

## 与框架 Service 的协作

### SceneService

- 查 `Scenes.has_id(scene_id)`、`Scenes.load_path()` 异步加载场景
- 读 `Scenes.asset_group(scene_id)`，切场景前 `App.assets.preload_group()`，离开后 `release_group()`

### UIService

- 查 `Uis.has_id(ui_id)`、`Uis.load_path()` 加载界面
- 读 `Uis.layer()` 挂到对应 CanvasLayer，`Uis.cache()` 决定 KEEP / DESTROY

### AssetService

- 查 `Assets.has_id(id)`、`Assets.load_path()` 按需加载
- `Assets.ids_in_group(group)` 供 `preload_group` / `release_group` 遍历
- `core` 组在 Boot 的 `AssetStage` 预热，永不释放

业务代码约定：**只认生成的常量类**，禁止裸 `res://` 路径。详见 [docs/conventions/naming.md](../../docs/conventions/naming.md)。

---

## 资产分组语义

```
core          ← 常驻，Boot 预热，不释放
level         ← 某场景独占，进场景预载、离场景释放
boss_fight    ← 自定义组，由 Scenes 页绑定到具体场景
```

- 分组在 **Assets 页** 创建；Scenes 页通过下拉引用
- 删除分组：组内资产归 `core`，场景的 `asset_group` 清空
- `core` 不可删除

---

## 架构要点（读代码时）

1. **状态上收**：`AssetGroupDock` 持有 `_manifest`，三子面板无持久化状态，只改 manifest 里的 Resource 引用（原地生效）。
2. **哑组件**：`AssetGroupTree` 不碰 manifest，拖拽只发 `reassign_requested`。
3. **全量生成**：manifest 是唯一真源，Generate 覆盖旧文件，不要手改生成物。
4. **编辑器隔离**：插件在 `addons/` 下，运行时 `src/` 不引用本插件；符合 [directory.md](../../docs/conventions/directory.md) 的 addons 例外说明。

---

## 常见操作速查

| 目标 | 操作 |
|---|---|
| 新增主菜单场景 | Scenes 页 Add → 填 id / 选 .tscn |
| 关卡资产随场景加载 | Assets 页建 `level` 组并拖入资产 → Scenes 页给 level 场景选 `asset_group = level` |
| 新增设置弹窗 | UI 页 Add → 选 Layer=POPUP, Cache=DESTROY |
| 改 id | 直接在详情面板改 → 自动存 manifest → Generate All |
| 批量导入目录资源 | 点 **Scan import** → 检查新增条目 → Generate All |
| 分组内拖资产 | Assets 页树里拖到目标分组行 |

---

## 相关文档

- [AssetService](../../docs/modules/asset-service.md) — 分组预载/释放
- [SceneService](../../docs/modules/scene-service.md) — 切场景与 asset_group
- [UIService](../../docs/modules/ui-service.md) — 分层与缓存策略
- [命名规范 — ID 常量类](../../docs/conventions/naming.md)
