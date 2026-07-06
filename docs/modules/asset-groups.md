# AssetManifest + Asset Groups 编辑器

> status: active | 最后更新: 2026-07-06
> 运行时代码: `res://src/resource/scripts/asset_manifest.gd` 等
> 编辑器插件: `res://addons/asset_groups/`

类 Unity Addressable Group 的资源清单方案。取代早期分散的 `scene_registry` / `ui_registry` /
`asset_map` 三份 `.tres`,把 scene / ui / asset 三类登记合并进**一份统一清单**,并配一个**可视化
编辑器插件**做增删与代码生成——彻底摆脱"只能在 Inspector 里手改、id 常量类要手动同步"的旧包袱。

## 一、运行时数据模型(src/resource/)

**一份清单,三类条目**。清单实例只有一个:`res://src/resource/data/asset_manifest.tres`,路径经
`ResPaths.MANIFEST`。三个 Service 都只 `load` 它:

| 类 | 文件 | 字段 |
|---|---|---|
| `AssetManifest` | `asset_manifest.gd` | `scenes: Array[SceneEntry]`、`uis: Array[UIEntry]`、`assets: Array[AssetEntry]`;`find_scene/find_ui/find_asset` |
| `SceneEntry` | `scene_entry.gd` | `id`、`scene_path`、`group`(进场景要预载/离场景释放的资产组,可空) |
| `UIEntry` | `ui_entry.gd` | `id`、`scene_path`、`layer`(枚举)、`cache`(枚举) |
| `AssetEntry` | `asset_entry.gd` | `id`、`path`、`group`(内存分组,默认 `&"core"`) |

为什么仍按类型分三个数组、而不是像 Unity 那样一个 group 混装多类:三类条目字段不同、且分属
`SceneService` / `UIService` / `AssetService` 三个消费者,分开存查询各走各的 `find_*`,类型安全且无需运行期分派。
"group"(内存分组)是横切概念:`AssetEntry.group` 标记它属于哪个可预载/释放的内存桶,`SceneEntry.group`
声明进入该场景时要预载哪个桶——两者取值同一命名空间(如 `&"level"`)。

### id 常量类(自动生成)

`SceneIds` / `UIIds` / `AssetIds`(`resource/scripts/*_ids.gd`)是业务代码引用 id 的唯一入口
(禁止裸字符串,见 [naming.md](../conventions/naming.md))。**这三份文件由编辑器插件"导出"时整体重写**,
文件头有"自动生成,请勿手改"标记——手改会在下次导出被覆盖。要增删 id,去插件面板改再导出。

## 二、编辑器插件(addons/asset_groups/)

编辑器底部面板 **Asset Groups**,前端"组件库"式的可视化编辑器。

```
addons/asset_groups/
  plugin.cfg / plugin.gd     # EditorPlugin 入口,挂底部面板
  manifest_io.gd             # 纯逻辑:读/写清单、生成 Ids、导出前校验(不碰 UI)
  dock/
    asset_group_dock.gd      # 主面板:三分区 + 导出栏 + 共享文件框,只做编排
    entry_section.gd         # 组件:一个类型分区(标题+折叠+新建+快速载入+拖拽)
    entry_card.gd            # 组件:一条条目卡片,按字段 schema 渲染
```

**关注点分离**:UI(dock/)只负责收集输入到内存中的 `AssetManifest`;真正的落盘与代码生成全在
`manifest_io.gd`(纯逻辑、可无头测试、可整目录搬走)。卡片完全由 schema 驱动,不认识三类差异——
新增字段只改 dock 里的 schema。

### 核心能力

- **按类型分区**:Scenes / UIs / Assets 三个可折叠分区,每区一列卡片,字段各自贴合类型
  (UI 有 layer/cache 下拉,Scene/Asset 有 group)。
- **快速载入 + 自动注入**:点「快速载入」选文件、或从 FileSystem 面板**拖拽**资源进分区,`path` 直接注入、
  `id` 由文件名派生(snake_case),重复 path 自动跳过。
- **可配置导出位置**:顶部两栏配置清单输出路径与 Ids 输出目录(带浏览按钮),记进项目元数据下次自动带出。
- **一键导出**:「导出」先做一致性校验(空 id / 空路径 / 同类 id 重复 → 拦截并提示),通过后
  `ResourceSaver.save` 写清单 + 重写三份 Ids 常量类 + 刷新 FileSystem。「重载」丢弃未导出改动、从磁盘重读。

### 启用

已在 `project.godot` 的 `[editor_plugins]` 里启用。首次打开项目后,编辑器底部出现 **Asset Groups** 页签。

## 三、失败与边界

- 清单加载失败(文件缺失/类型不符):三个 Service 的 `_manifest` 为 null,查找一律返回 null / 走各自失败路径
  (`replace` 失败、`open` 记 error、`get_asset` 返回 null),不崩。
- 插件是**编辑器专用**,不参与运行时、不被 `src/` 引用、不打进游戏包(见 [directory.md](../conventions/directory.md) 的 addons 例外)。
- 校验只在导出时做,不阻止你在面板里暂存半成品;真正写盘前才拦截。

## 四、测试要点

- 运行时:统一清单加载 + 三 Service 查找 + 分组预载/释放,已随启动烟测与 M1/M5 无头测试覆盖。
- 插件 IO:`manifest_io.gd` 的读写往返、Ids 生成内容、校验(重复/空)可无头验证(纯逻辑,不依赖编辑器 UI)。
