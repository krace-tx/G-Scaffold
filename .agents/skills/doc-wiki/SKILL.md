---
name: doc-wiki
description: 项目文档索引地图 (Doc Wiki)。记录所有 _doc_*.md 模块文档的位置与功能说明，用于 Agent 分析和查阅相关文档。
---

# 项目文档索引 (Doc Wiki)

本项目采用 `_doc_{feature}.md` 的命名规范来管理各个模块的设计与使用说明（带有下划线前缀以保证文档永远排序在目录最上方）。
当 Agent 遇到特定的业务逻辑或底层模块问题时，**必须**通过本索引找到并阅读对应的文档以获取上下文。

## 当前文档地图

```text
docs/
└── _doc_android_environment.md                   # Android 导出与环境配置指南 (Java SDK、Android SDK、Keystore)
src/
├── assets/
│   └── _doc_assets.md                            # 资产加载池、内存与磁盘缓存管理服务说明
├── resource/
│   └── _doc_resource.md                          # 渲染材质与动效资源库 (SDF圆角Shader、扫光特效、Spine动画)
├── framework/
│   ├── _doc_framework.md                         # 框架层核心架构、全局服务聚合根(App)与事件总线(Bus)设计
│   ├── core/
│   │   ├── boot/
│   │   │   └── _doc_boot.md                      # 启动管线机制，多阶段异步加载与失败降级策略
│   │   ├── utils/
│   │   │   └── _doc_utils.md                     # 无状态纯函数工具库 (文件、时间、节点操作、编解码等)
│   │   └── services/
│   │       ├── _doc_services.md                  # 基础服务层说明，列举网络、音频、资产等核心服务
│   │       ├── locale_service/
│   │       │   └── _doc_locale_service.md        # 多语言文本与区域格式化服务说明
│   │       └── persist_service/
│   │           └── _doc_persist_service.md       # 本地与云端数据持久化、存档服务说明
│   └── infra/
│       ├── params/
│       │   └── _doc_params.md                    # 契约实体基类 (BaseParams)，基于反射的自动 Dict 序列化
│       ├── scene/
│       │   └── _doc_scene.md                     # 场景流转与管理，压栈替换机制与生命周期钩子
│       └── ui/
│           └── _doc_ui.md                        # 基础 UI 抽象，按钮默认音效/震动/缩放封装
└── game/
    ├── _doc_game.md                              # 游戏业务与核心玩法聚合层 (Game 单例、管理器矩阵、GameBoot 流水线)
    ├── core/
    │   └── platform/
    │       └── _doc_platform.md                  # 平台服务层 (广告/埋点/内购/登录/分享) 架构与门面说明
    └── scenes/
        ├── common/
        │   └── popup/
        │       └── toast/
        │           └── _doc_toast.md                 # 全局通用 Toast 浮层提示条规范与调用方式
        ├── gallery/
        │   └── _doc_gallery.md                   # 图库相册模块：三级视图、Fade切换、分批流式异步加载与防爆显存
        └── level/
            └── _doc_level.md                     # 关卡玩法模块架构：门面、Node状态机、网格渲染与技能编排
```

## 使用与维护原则

1. **按需查阅**：不要盲目猜测项目的底层实现逻辑。如果任务涉及上述模块，优先使用 `view_file` 查阅对应的 `_doc_*.md` 文档。
2. **同步更新**：如果你在开发中新建或迁移了 `_doc_{feature}.md` 文档，**必须**同步修改本文件 (`.agents/skills/doc-wiki/SKILL.md`)，将新文档的位置和简要功能补充到上方的“当前文档地图”中，保持 Wiki 最新。
