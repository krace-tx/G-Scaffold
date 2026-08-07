# G-Scaffold Agent 指南与项目规范

> 本文件为 G-Scaffold 项目的 AI Agent 行为准则与架构规范约束。Agent 在执行任何代码修改、重构或新增功能任务时，必须严格遵守以下规则。

---

## 一、 项目定位与核心架构

G-Scaffold 是基于 **Godot 4+** 的模块化、高可维护性 GDScript 游戏框架。

### 1. 三层架构与依赖铁律

项目代码严格按以下三层划分，**依赖只能单向向下**：

```
┌─────────────────────────────────────────────┐
│  src/game/       业务层 (允许与本游戏强耦合) │
│    entities / scenes / ui / services(业务)   │
└──────────────┬──────────────────────────────┘
               │ 只能向下调用
┌──────────────▼──────────────────────────────┐
│  src/platform/   防腐层 (隔离第三方 SDK)     │
│    ads / android / ios                       │
└──────────────┬──────────────────────────────┘
               │ 只能向下调用
┌──────────────▼──────────────────────────────┐
│  src/framework/  内核层 (通用的游戏框架核心)  │
│    autoloads / core / managers               │
└─────────────────────────────────────────────┘
```

- **依赖铁律**：`game → platform → framework`。
  - `src/framework/` 内严禁出现任何 `res://src/game/` 或 `res://src/platform/` 引用。
  - `src/platform/` 内严禁出现任何 `res://src/game/` 引用。
- **纯数据隔离**：`src/assets/`（媒体资源）与 `src/resource/`（配置/Resource类）被各层引用，但不得引用任何代码层。

### 2. 全局入口与通信规范

- **全局仅有两个 Autoload**：
  1. `App` (`src/framework/autoloads/app.gd`)：类型化服务聚合根（持有 `App.ui`、`App.scenes`、`App.save` 等引用）。
  2. `Bus` (`src/framework/autoloads/bus.gd`)：全局信号总线，**仅用于广播领域事件（已发生的事实）**。
- **服务（Service）不是 Autoload**：
  - 框架服务均为普通 GDScript 类（`class_name XxxService`），由 `BootPipeline`（启动管线）显式创建并注入 `App` 中。
- **通信铁律**：
  - **命令/主动调用**：走 API（如 `App.save.save_game()`）。
  - **事件广播**：走 `Bus` 信号（如 `Bus.player_died.emit()`）。
  - 模块间禁止使用 `get_node` / 父子路径互相反向抓取。

### 3. 平台 SDK 与存档规范

- **第三方 SDK 必须防腐**：业务代码严禁直接调用第三方 SDK，必须经由 `src/platform/` 的 Provider 门面。必须提供 `NullProvider` 作为无 SDK 环境（如 PC/Editor）的 Fallback 实现。
- **存档规范**：存档必须使用版本化 JSON，保存在 `user://` 下。禁止将 Godot `.tres` Resource 对象直接序列化保存到 `user://`。

---

## 二、 GDScript 编码规范

所有 GDScript 代码须符合以下硬性规定：

### 1. 强制 `#region` 代码分块

超过 40 行或包含 3 个以上方法的脚本，**必须**使用以下固定顺序的 `#region` 分块：

```gdscript
@tool
class_name FooService
extends Node

## 一句话说明类职责

#region Signals
signal something_happened(payload: int)
#endregion

#region Constants & Enums
enum State { IDLE, RUNNING, DONE }
const MAX_RETRY: int = 3
#endregion

#region Exports & State
@export var speed: float = 4.5
var _state: State = State.IDLE          # 私有成员变量下划线前缀
@onready var _timer: Timer = $Timer
#endregion

#region Lifecycle
func _ready() -> void:
	pass
#endregion

#region Public API
## 对外公开 API 方法
func start() -> void:
	pass
#endregion

#region Internal
func _do_the_thing() -> void:
	pass
#endregion
```

- **分块顺序绝对固定**：`Signals` → `Constants & Enums` → `Exports & State` → `Lifecycle` → `Public API` → `Internal`。
- 不用到的 region 可以省略，不要留下空的 region。

### 2. 反嵌套与静态类型

- **函数缩进硬上限 3 层**：优先使用 Guard Clause（卫语句 `if condition: return`）前置返回，保持主逻辑在最外缩进层级。
- **强制静态类型**：参数、返回值、变量声明均须标注显式类型（例如 `func process_item(item: ItemData) -> bool:`）。
- **注释规范**：对外 Public API 统一在方法定义上方使用 `##` 撰写 GDScript 规范文档注释。

---

## 三、 目录归属与文件位置决策

创建新文件时按以下优先级判断存放目录：

1. **媒体文件 (audio/fonts/textures)** → `src/assets/`
2. **Resource 定义或数据配置 (.tres/JSON)** → `src/resource/scripts/` 或 `src/resource/data/`
3. **平台 API / 第三方 SDK 封装** → `src/platform/`
4. **与本游戏业务无关、通用的框架能力**：
   - 无场景树依赖（如 Log, Config, Save） → `src/framework/core/`
   - 有场景树依赖（如 UI, Scene, Audio） → `src/framework/managers/`
5. **本游戏特有逻辑 (Player, Enemy, MainLevel, GameUI)** → `src/game/`
6. **不确定时优先放 `src/game/`**（业务提升为框架容易，框架降级为业务困难）。

---

## 四、 Agent 工作流程要求

1. **先查阅文档再动刀**：在修改或新增任何框架服务之前，先阅读 `docs/architecture/` 和 `docs/modules/` 中对应的说明文档。
2. **代码与文档同步更新**：新增框架服务必须同步在 `docs/modules/` 中建立对应的说明文档；修改服务行为时必须更新文档。
3. **架构违规自我检查**：
   - 检查是否有在 `framework` 或 `platform` 中硬编码 `src/game/` 路径。
   - 检查是否有跳过 `App` / `Bus` 直接在跨层代码中抓取节点。
   - 检查是否遗漏静态类型标注或未遵守 `#region` 顺序。
