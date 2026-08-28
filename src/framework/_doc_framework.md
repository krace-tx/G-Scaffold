# Framework

## 核心

框架层提供全局统一的服务访问点（Service Locator）与跨模块的解耦通信支持（领域事件总线）。
负责调度系统全局生命周期，通过启动管线以依赖注入的形式挂载各类基础底层能力。
不涉及具体的游戏玩法与业务逻辑，不处理特定功能的状态校验。

---

## 细节

- 入口：系统通过 `app.gd` 作为唯一的引擎 `AutoLoad` 挂载点，集中接管全局生命周期与 OS 硬件事件。
- 启动：通过 `BootPipeline` 链式加载各种 `BootStage` 来完成底层模块的异步初始化。
- 容错：使用 `Result` 类型封装所有容易失败的操作，强制上层调用处通过 `is_ok()` 和 `is_err()` 处理分支，避免静默报错。
- 通信：使用 `bus.gd` 发布不可变的全局事实，只在事情发生后进行广播（如 `app_paused`、`scene_changed`），不承载具体命令。
- 基础层：功能（日志、持久化、网络等）抽象为各司其职的 `Service`，隔绝原生引擎 API，为上层业务提供稳定防腐的接口。

```text
src/framework/
├── autoloads/            
│   ├── app.gd            # 全局服务聚合根 (Service Locator)，分发 OS 层面生命周期
│   └── bus.gd            # 全局领域事件总线，只广播已发生的事实信号
├── core/                 
│   ├── boot/             # 启动管线，定义 BootPipeline 与具体加载阶段 BootStage
│   ├── services/         # 具体服务实现目录 (日志、时间、语言、资产、网络等)
│   ├── utils/            # 无状态的纯函数工具库 (文件、时间、节点等计算与处理)
│   └── result.gd         # 可失败操作的统一返回值封装类型
└── infra/                
	├── cache/            # 缓存基建模块 (如 BudgetCache)
	├── scene/            # 场景树流转与切换遮罩 (SceneService, BaseScene)
	└── ui/               # 基础 UI 控件层基类 (BaseUI)
```

---

## 样例

```gdscript
# 访问全局服务聚合根 (Service Locator)
App.log.info("module", "Framework is ready.")
App.audio.set_paused(true)

# 安全调用可能失败的基础层服务操作
var res := App.persist.load_data("user_profile")
if res.is_ok():
	print("User data:", res.value)
else:
	App.log.error("module", "Failed to load: " + res.error)

# 监听全局事件总线 (不可变事实)
Bus.app_paused.connect(_on_app_paused)
```
