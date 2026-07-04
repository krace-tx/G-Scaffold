# 文档网络图谱

> status: active | 最后更新: 2026-07-04

节点 = 文档,箭头 = Markdown 链接引用(A → B 表示 A 引用了 B)。用于快速判断:改一篇文档会波及谁、新人该从哪个枢纽读起。

```mermaid
flowchart LR
    README["README.md<br/>(文档地图·入口)"]

    subgraph PLAN["plan/ 计划"]
        P_R["README"]
        DEV["development-plan<br/>开发计划 M0~M6"]
    end

    subgraph ARCH["architecture/ 架构"]
        OV["overview<br/>分层与依赖铁律"]
        BOOT["boot-sequence<br/>启动管线"]
        COMM["communication<br/>通信规范"]
        subgraph ADR["decisions/ ADR"]
            ADR_R["README"]
            ADR_T["template"]
            A1["0001 App聚合根"]
            A2["0002 Bus只发事实"]
            A3["0003 版本化存档"]
            A4["0004 平台防腐层"]
        end
    end

    subgraph MOD["modules/ 模块"]
        MOD_R["README"]
        MOD_T["template"]
        SCENE["scene-service<br/>(示例规格)"]
    end

    subgraph CONV["conventions/ 规范"]
        DIR["directory<br/>目录归属"]
        NAM["naming<br/>命名"]
        STYLE["coding-style<br/>编码"]
        GIT["git<br/>工作流"]
    end

    subgraph GUIDE["guides/ 指南"]
        G_SVC["add-a-service"]
        G_UI["add-a-ui"]
        G_PLAT["add-a-platform-provider"]
    end

    README --> OV
    README --> ADR_R
    README --> MOD_R
    README --> DIR
    README --> G_SVC
    README --> DEV

    OV --> BOOT
    OV --> COMM
    OV --> A1
    OV --> A2
    OV --> A3
    OV --> A4

    ADR_R --> ADR_T
    ADR_R --> A1
    ADR_R --> A2
    ADR_R --> A3
    ADR_R --> A4
    A1 --> G_SVC
    A2 --> COMM

    MOD_R --> MOD_T
    MOD_R --> SCENE
    MOD_T --> BOOT

    STYLE --> NAM
    NAM --> A1

    G_SVC --> BOOT
    G_SVC --> A1
    G_SVC --> MOD_T
    G_PLAT --> A4

    P_R --> DEV
    DEV --> A3
    DEV --> DIR
    DEV --> SCENE

    style README fill:#4a90d9,color:#fff
    style OV fill:#d96b4a,color:#fff
    style A1 fill:#8e6bbf,color:#fff
    style BOOT fill:#d96b4a,color:#fff
```

## 枢纽文档(被引用最多,改动需谨慎)

| 文档 | 入度 | 被谁引用 |
|---|---|---|
| ADR-0001 App 聚合根 | 4 | overview、ADR 索引、naming、add-a-service |
| boot-sequence 启动管线 | 3 | overview、模块模板、add-a-service |
| ADR-0003 版本化存档 | 3 | overview、ADR 索引、开发计划 |
| ADR-0004 平台防腐层 | 3 | overview、ADR 索引、add-a-platform-provider |

改这些文档时,顺着入边把引用方检查一遍。

## 孤岛文档(无任何入链,只能靠目录浏览发现)

- `conventions/git.md`
- `guides/add-a-ui.md`

孤岛不是错误(README 的文档地图按目录指路),但新增文档时留意:**如果一篇文档既无入链、又不在任何索引表里,它就等于不存在。**

## 维护规则

1. 新增文档或增删跨文档链接时,同步更新本图谱
2. 重新提取真实链接关系,用此命令核对(在 `docs/` 下运行):
   ```bash
   for f in $(find . -name '*.md' | sort); do
     grep -oE '\]\([^)#]+\.md\)' "$f" | sed "s|](\(.*\))|$f -> \1|"
   done
   ```
3. 图谱与实际链接不符时,以实际链接为准修图,不要为了图好看而改文档结构
