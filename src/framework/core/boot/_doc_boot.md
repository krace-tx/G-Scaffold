# Boot (启动管线)

## 核心

提供应用启动时的多阶段（Stage）异步初始化管线。
调度所有框架层、设施层的基础模块挂载。统一处理服务加载顺序，并在某个阶段初始化失败时，决定应用是安全熔断（STOP）还是降级运行（CONTINUE）。

---

## 细节

- **启动入口**：整个系统启动由 `BootPipeline` 接管。`App.bootstrap()` 会调用并等待管线走完。
- **阶段划分**：每个异步初始化的任务被封装成一个 `BootStage` 子类。
- **错误处理**：某个 `BootStage` 返回 `Result.err` 时，根据 `on_fail()` 策略处理。默认 `STOP` 会直接中断并阻断后续阶段；`CONTINUE` 则只输出警告并强行继续。

```text
src/framework/core/boot/
├── boot_pipeline.gd          # 启动管线执行器，负责按序调度各 BootStage 并汇总启动耗时
├── boot_stage.gd             # 单个启动阶段的抽象基类，子类需重写 id() 与 run() 并负责打日志
└── stages/                   # 具体的阶段实现目录 (如 CoreServiceStage)
```

---

## 样例

```gdscript
# 定义一个新的启动阶段
class_name NetworkBootStage extends BootStage

func id() -> String:
    return "Boot_Network"

func on_fail() -> Failure:
    return Failure.CONTINUE # 如果连不上网也允许进单机模式

func run() -> Result:
    # 执行异步初始化逻辑
    var req = await App.network.init_pool()
    if req.is_ok():
        return Result.ok()
    return Result.err("Network pool init failed")
```
