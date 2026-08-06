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
├── plugin.gd / plugin.cfg     # 插件入口，挂到主屏幕页签
├── README.md                  # 本文档
│
├── internal/                  # 插件私有工具(不注册 class_name)
│   └── asset_group_result.gd
├── editor/                    # 编辑器 UI 层（只改 manifest，不管生成细节）
│   ├── asset_group_dock.*     # 根面板：加载/保存 manifest、Scan、Generate All
│   ├── panels/
│   │   ├── assets/            # Assets 页：树控制器 + 详情展示 + 总调度
│   │   ├── scenes/            # Scenes 页：场景 id + 路径 + 关联资产组
│   │   └── ui/                # UI 页：界面 id + 路径 + 层级 + 缓存策略
│   └── widgets/               # 共用控件：空状态、路径输入、样式
│
├── model/                     # 数据模型（Resource 脚本）
│   ├── edit/                  # 编辑态（Dock 读写的唯一真源）
│   │   ├── edit_asset_manifest.gd
│   │   └── edit_scene_entry.gd / edit_ui_entry.gd / edit_asset_entry.gd
│   └── runtime/               # 运行时注册表（Generate 产出的 .tres 形态）
│       ├── runtime_scene_registry.gd / runtime_scene_entry.gd
│       ├── runtime_ui_registry.gd / runtime_ui_entry.gd
│       └── runtime_asset_registry.gd / runtime_asset_entry.gd
│
└── codegen/                   # 扫描、校验、生成管线
	├── manifest_scanner.gd
	├── manifest_validator.gd
	├── manifest_entries.gd
	├── generator_utils.gd
	├── accessors_generator.gd
	└── registry_generator.gd
```

---

## 两层数据模型

### 1. 编辑态（Edit）— Dock 读写的唯一真源

持久化文件：`res://src/resource/data/asset_manifest.tres`

| 类型 | 字段 | 说明 |
|---|---|---|
| `EditAssetManifest` | `scenes`, `uis`, `assets`, `groups` | 根资源，三页共享同一实例 |
| `EditSceneEntry` | `id`, `scene_path` | 顶层场景；与 UI 一样只有 id + 路径 |
| `EditUIEntry` | `id`, `scene_path`, `layer`, `cache` | 界面；层级与缓存策略供 UIService 使用 |
| `EditAssetEntry` | `id`, `path`, `group` | 任意资源文件；`group` 是预载/释放的单位 |

`EditAssetManifest` 还提供分组相关 API：

- `collect_groups()` — 合并显式分组 + 资产引用的组名
- `add_group` / `remove_group` / `rename_group` — 仅在 Assets 页管理分组
- `find_scene` / `find_ui` / `find_asset` / `assets_in_group`

默认存在 `core` 分组（常驻资产，Boot 时预热，永不释放）。

### 2. 运行时（Runtime）— Generate 产物，对接框架 Service

Generate 时由 `RegistryGenerator` **全量重建、整份覆盖**，不做增量 merge。

| 注册表 | 条目字段 | 消费方 |
|---|---|---|
| `RuntimeSceneRegistry` | `id`, `scene_path` | `SceneService` → `Scenes.xxx()` |
| `RuntimeUIRegistry` | `id`, `scene_path`, `layer`, `cache` | `UIService` → `Uis.xxx()` |
| `RuntimeAssetRegistry` | `id`, `path`, `group` | `AssetService` → `Assets.xxx()` |

**为何存路径字符串而非 PackedScene 引用？**  
注册表 .tres 若直接引用资源本体，`load` 时会把所有条目同步拉进内存。运行时 Service 只读生成的查表类（含 `uid://` 加载键），按需加载。

`EditUIEntry.Layer/Cache` 与 `RuntimeUIEntry.Layer/Cache` **枚举按序对齐**（HUD < WINDOW < … < DEBUG），生成器经 `int()` 转换。

---

## 编辑器工作流

### 打开面板

启用插件后，编辑器顶部主屏幕标签栏（与 2D / 3D 同级）会出现 **Asset Groups**。

### 三个 Tab 的分工

| Tab | 做什么 | 分组权限 |
|---|---|---|
| **Scenes** | 登记顶层场景（id + 路径） | 无 |
| **UI** | 登记界面，选 Layer / Cache | 无 |
| **Assets** | 按目录层级树管理资产（`TEXTURES_ENTITIES` → `TEXTURES` > `ENTITIES`），支持拖拽换组 | **唯一** 可新建/重命名/删除分组 |

### 顶层按钮

| 按钮 | 行为 |
|---|---|
| **Reload** | 从磁盘重载 `asset_manifest.tres`，丢弃未保存编辑 |
| **Scan import** | 扫描 `src/game/scenes`、`src/game/ui`、`src/assets`，追加尚未登记的资源（id = 文件名；Assets 的 group 按目录层级生成，如 `textures/entities/foo.png` → `TEXTURES_ENTITIES`；路径已存在则跳过） |
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
	└─ ManifestValidator.soft_warnings()     ← 草稿跳过,仅提示
```

**空 manifest 也可 Generate**：会写出空的 `_TABLE` / `_GROUPS` 模板，`SceneService` / `UIService` / `AssetService` 可正常编译运行。业务代码里的 `Scenes.MAIN_MENU` 等常量需 Scan import 或手动登记后再 Generate 才有。

### 硬错误（阻断 Generate）

- 某类型内 `id` 为空或重复
- `scene_path` / `path` 为空
- id 不是合法标识符，或转大写后常量名冲突（IdsGenerator）

### 软警告（不阻断）

- 有条目只填了 id 或路径之一（草稿行，Generate 会跳过）

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

Scan import 时，Assets 的 `group` 严格对应 `src/assets/` 下的目录层级：每一级目录名合法化后转大写，再用下划线连接。编辑器左侧树会按 `_` 拆成文件夹层级展示，例如 `TEXTURES_ENTITIES_CONFIG` 显示为 `TEXTURES` → `ENTITIES` → `CONFIG`。

```
core          ← 常驻，Boot 预热，不释放
TEXTURES/…    ← 按目录层级自动分组；业务代码按需 preload_group 或 Assets.xxx() 加载
```

- 右键文件夹：Add child group / Rename / Delete（仅对已登记或有资产的组）
- 工具栏文件夹按钮：在选中文件夹下新建子组（自动带上 `父路径_` 前缀）

- 分组仅在 **Assets 页** 管理（资产归属）
- 删除分组：组内资产归 `core`
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
| 关卡资产按需加载 | Assets 页建组并归类 → 业务代码 `App.assets.preload_group()` 或 `Assets.xxx()` |
| 新增设置弹窗 | UI 页 Add → 选 Layer=POPUP, Cache=DESTROY |
| 改 id | 直接在详情面板改 → 自动存 manifest → Generate All |
| 批量导入目录资源 | 点 **Scan import** → 检查新增条目 → Generate All |
| 分组内拖资产 | Assets 页树里拖到目标分组行 |

---

## 相关文档

- [AssetService](../../docs/modules/asset-service.md) — 分组预载/释放
- [SceneService](../../docs/modules/scene-service.md) — 切场景生命周期
- [UIService](../../docs/modules/ui-service.md) — 分层与缓存策略
- [命名规范 — ID 常量类](../../docs/conventions/naming.md)
