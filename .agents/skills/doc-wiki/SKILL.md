---
name: doc-wiki
description: 项目文档索引地图 (Doc Wiki)。记录所有 _doc_*.md 模块文档的位置与功能说明，用于 Agent 分析和查阅相关文档。
---

# 项目文档地图 (Doc Wiki)

本项目采用模块化就近文档设计。每个核心模块目录下均放置有专属的 `_doc_*.md` 规范与实现文档。

## 📑 全局与框架层文档

| 模块 / 路径 | 文档文件 | 核心职责与设计要点 |
| :--- | :--- | :--- |
| **Android 环境** (`docs/`) | `docs/_doc_android_environment.md` | Android JDK 17 环境搭建、导出预设、网络安全与故障排查 |
| **Framework 顶层** (`src/framework/`) | `_doc_framework.md` | 框架层整体架构、三层设计模式、服务注册体系 |
| **Boot 管线** (`src/framework/core/boot/`) | `_doc_boot.md` | 启动生命周期、Stage 阶段编排与故障熔断处理 |
| **通用工具库** (`src/framework/core/utils/`) | `_doc_utils.md` | TimeUtils, NodeUtils, FileUtils, VibrateUtils 等通用工具约定 |
| **服务层** (`src/framework/core/services/`) | `_doc_services.md` | 11 大核心服务定义、依赖关系与生命周期 |
| **多语言服务** (`.../locale_service/`) | `_doc_locale_service.md` | 多语言配置、运行时动态切换与 CSV 解析 |
| **持久化服务** (`.../persist_service/`) | `_doc_persist_service.md` | 内存/磁盘多级存储、Resource 编解码与容灾降级 |
| **UI 基础设施** (`src/framework/infra/ui/`) | `_doc_ui.md` | BaseUI、BaseTextureButton 规范与分辨率适配 |
| **场景流转** (`src/framework/infra/scene/`) | `_doc_scene.md` | BaseScene 生命周期、SceneStack 栈式导航与转场 |
| **参数传递** (`src/framework/infra/params/`) | `_doc_params.md` | BaseParams 强类型参数封装与上下文传递 |
| **资产与资源** (`src/assets/`, `src/resource/`)| `_doc_assets.md`, `_doc_resource.md` | 资产组织规范、Shader 材质与预制体约定 |
