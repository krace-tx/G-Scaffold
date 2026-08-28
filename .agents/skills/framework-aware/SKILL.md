---
name: framework-aware
description: 编码前自动检索 framework 层文档注入。确保 Agent 在编写或修改涉及框架封装的代码前，先查阅对应的 _doc_*.md 文档以获取正确的基类约定、服务调用方式与架构约束。
---

# 框架感知编码 (Framework-Aware Coding Skill)

> 核心目标：**杜绝凭经验臆造代码**。涉及 framework 层的封装时，必须先读对应文档，用对基类、调对服务、遵循约定。

## 一、触发条件

当任务涉及以下动作时**必须触发**本流程：

- 新建或修改继承自框架基类的代码（`BaseScene`、`BaseUI`、`BaseParams`、`BaseResponse` 等）
- 新建或修改涉及场景生命周期、UI 交互、控件封装的代码
- 调用 `App.xxx` 全局服务（网络、持久化、音频、多语言、资产、时间、环境等）
- 使用框架层工具函数（`NodeUtils`、`FileUtils`、`AsyncUtils` 等）
- 涉及启动流程（`BootStage`、`BootPipeline`）或事件总线（`Bus`）

**不触发的场景**：纯文档编写、纯资源操作（重命名贴图、调参数）、git 操作、纯分析/回答问题。

## 二、匹配表（关键词 → 文档路径）

任务中出现以下关键词或操作意图时，**必须**先 `view_file` 查阅对应文档：

| 关键词 / 操作意图 | 应查阅文档 | 你要确认什么 |
|---|---|---|
| 新建场景、场景切换、push/pop/replace | `src/framework/infra/scene/_doc_scene.md` | 必须继承 `BaseScene`，使用 4 大生命周期钩子 |
| 新建 UI 层、控件树编排 | `src/framework/infra/ui/_doc_ui.md` | UI 根节点必须继承 `BaseUI`，节点名为 `UI` |
| 按钮、点击反馈、音效震动 | `src/framework/infra/ui/_doc_ui.md` | 使用 `BaseTextureButton`，不要手写缩放/音效 |
| App.xxx、全局服务、Service Locator | `src/framework/_doc_framework.md` | 通过 `App` 聚合根访问，了解 Bus 事件总线 |
| 启动流程、BootStage、初始化 | `src/framework/core/boot/_doc_boot.md` | 遵循启动管线与阶段加载机制 |
| 网络请求、HTTP、Token、鉴权 | `src/framework/core/services/_doc_services.md` | 使用 `App.net`，返回值为 `Result` 类型 |
| 持久化、存档、本地存储 | `src/framework/core/services/persist_service/_doc_persist_service.md` | 使用 `App.persist`，了解读写链与回灌范围 |
| 多语言、翻译、locale | `src/framework/core/services/locale_service/_doc_locale_service.md` | 使用 `App.locale`，了解配置表与格式化 |
| 音频、BGM、SFX | `src/framework/core/services/_doc_services.md` | 使用 `App.audio`，了解分组播放与淡变 |
| 资产加载、纹理缓存、内存池 | `src/assets/_doc_assets.md` | 使用 `App.asset`，了解缓存策略 |
| 材质、Shader、Spine动画 | `src/resource/_doc_resource.md` | 继承 COLOR.a、动态 duplicate、使用 Catalog 路由 |
| 工具函数、节点操作、文件读写 | `src/framework/core/utils/_doc_utils.md` | 优先使用已有的 Utils（NodeUtils, FileUtils 等） |
| Params、契约实体、from_dict/to_dict | `src/framework/infra/params/_doc_params.md` | 必须继承 `BaseParams`，无需手写序列化方法 |
| 游戏核心业务、Profile、LevelManager | `src/game/_doc_game.md` | 业务聚合根 `Game`、进度推进与数据存盘 |
| 图库、相册、大图预览、Gallery | `src/game/scenes/gallery/_doc_gallery.md` | 了解三级视图切换、Fade 动效与流式分批异步加载 |
| 关卡玩法、状态机、拼图网格 | `src/game/scenes/level/_doc_level.md` | 状态机驱动、网格生成与技能消费流程 |
| Result、错误处理、is_ok/is_err | `src/framework/_doc_framework.md` | 使用 `Result` 类型包装可失败操作 |

## 三、执行流程

```
收到任务 → 扫描关键词 → 命中匹配表？
                          ├── 是 → view_file 查阅文档 → 提取约束 → 带着约束写代码
                          └── 否 → 正常编码（不阻塞）
```

### 具体步骤

1. **扫描**：通读任务描述，提取涉及的模块关键词。
2. **碰撞**：与上方匹配表逐条对照。可以命中多条。
3. **注入**：对每条命中，用 `view_file` 查阅对应的 `_doc_*.md`。
4. **提取**：从文档中提取与当前任务直接相关的约束（基类、命名、调用方式）。
5. **编码**：带着这些约束进入实现阶段。

### 声明格式

在回复开头的 Skill 声明中体现注入了哪些文档：

```
> 🛠️ **已加载 Skill**：`framework-aware`
> 📖 **已注入文档**：`_doc_scene.md`、`_doc_ui.md`
```

如果扫描后未命中任何条目，则不需要额外声明。

## 四、常见的违反案例

**❌ 不查文档直接写**

```gdscript
# 新建场景时直接继承 Node，没用 BaseScene
class_name MyScene extends Node
```

**✅ 查完文档再写**

```gdscript
# 查阅 _doc_scene.md 后，使用正确的基类与生命周期钩子
class_name MyScene extends BaseScene

func _on_enter(params: Dictionary = {}) -> void:
    # 初始化逻辑
    pass
```

**❌ 手写按钮音效和缩放**

```gdscript
# 自己实现了按钮点击反馈
func _on_btn_pressed():
    AudioServer.play(...)
    tween.scale(...)
```

**✅ 使用框架封装**

```gdscript
# 查阅 _doc_ui.md 后，直接使用 BaseTextureButton
# 音效、缩放、震动在基类自动处理，业务只需连 pressed 信号
_btn.pressed.connect(_on_start_game)
```

## 五、维护

- 当 framework 层新增模块或文档时，同步更新上方匹配表。
- 匹配表只收录有 `_doc_*.md` 文档的模块；没有文档的模块不加入匹配表（避免查阅空气）。
