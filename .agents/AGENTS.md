# funny-jigsaw Agent 图谱

<identity>
你是一个专注于 Godot 引擎与游戏开发（funny-jigsaw 项目）的 AI Agent。
你的核心工作方式是“按需查阅”：根据当前面临的具体问题或任务，从 `skills/` 或 `rules/` 库中加载相应的上下文和规范，避免一次性加载过多无关信息。
</identity>

<agent_directives>
**强制响应规范**：在回复用户的任何提问或开始执行任务前，你**必须**在回答的最开头明确声明本次采用了哪些 Skill。以此让开发者清晰感知规则是否生效。
（示例：“> 🛠️ **已加载 Skill**：`safe-coding`, `git-commit`” 或 “> 🛠️ **已加载 Skill**：无”）
</agent_directives>

<skill_map>
作为 Agent，在执行具体动作前，请根据下表判断并查阅对应的专门能力文档（Skill / Rule）：

- **代码提交与版本控制**：当你需要执行 git commit、分支管理等操作时，请主动查阅 `skills/git-commit`。
- **安全编码与防污染**：当你需要执行逻辑修改、代码生成等容易对项目造成较大影响的任务时，请主动查阅 `skills/safe-coding`。
- **框架感知编码**：当你需要新建或修改涉及场景、UI、服务调用、工具函数等 framework 层封装的代码时，请主动查阅 `skills/framework-aware`。
- **模块文档编写**：当你需要新建或改写 `_doc_*.md`、功能说明文档时，请主动查阅 `skills/write-docs`。
- **查阅文档索引**：当你需要了解项目架构、特定模块设计或寻找参考文档时，请主动查阅 `skills/doc-wiki` (Doc Wiki)。
</skill_map>

<file_graph>
```text
.agents/
├── AGENTS.md                 # 全局入口与 Agent 核心定义 (本文件)
└── skills/                   # 专项能力库 (按需查阅)
    ├── doc-wiki/
    │   └── SKILL.md          # 项目文档地图 (Doc Wiki)，记录所有 _doc_*.md 位置
    ├── framework-aware/
    │   └── SKILL.md          # 框架感知编码，编码前自动检索 framework 层文档注入
    ├── git-commit/
    │   └── SKILL.md          # Git 提交规范与流程指南
    ├── safe-coding/
    │   └── SKILL.md          # 安全编码规范
    └── write-docs/
        └── SKILL.md          # 模块文档编写思路
```
</file_graph>