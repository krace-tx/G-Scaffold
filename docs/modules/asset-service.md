# AssetService 模块文档

> status: active | 最后更新: 2026-07-04 | 代码位置: `res://src/framework/managers/asset_service.gd`

## 职责与边界

**做什么**:按统一清单 `asset_manifest.tres` 的 asset 条目(id → 路径 + 分组)管理资产的加载/缓存/释放。核心目标是**控制内存峰值**:核心资产常驻,场景/关卡资产进场景预载、离场景释放。清单由 Asset Groups 编辑器插件维护(见 [asset-groups.md](asset-groups.md))。

**明确不做什么**:
- 不做异步/线程加载——当前用同步 `load()`(分组体积可控);需要时再引入 `load_threaded`
- 不管场景切换本身——那是 SceneService(它按场景的 `asset_group` 调用本服务预载/释放)
- 不生成/处理资产——只按登记的路径加载

## 公开 API

```gdscript
func get_asset(id: StringName) -> Resource      # 取用(未缓存则按需加载)
func preload_group(group: StringName) -> void   # 预载整组到缓存
func release_group(group: StringName) -> void   # 释放整组缓存引用
func is_cached(id: StringName) -> bool
```

资产 id → 路径/分组的映射在 `asset_manifest.tres` 的 `assets` 数组里,代码用 `AssetIds.XXX` 常量引用,清单路径经 `ResPaths.MANIFEST`。

## 分组与释放

`AssetEntry` 有 `group` 字段。分组是预载/释放的单位:
- `&"core"`:常驻资产,Bootstrap 阶段 5 预热,永不释放
- 各场景/关卡一组:进场景预载、离场景释放

**释放语义**:`release_group` 只是从缓存 `_cache` 里 `erase`(丢引用)。资源在**无其他持有者**时才被引擎真正回收——若场景仍在用某资产,它不会因 release 而消失(引用计数保护)。已验证 release 后 WeakRef 变空(确实回收)。

## 与 SceneService 的协作

`SceneEntry` 有可空的 `group` 字段。SceneService 切场景时:
1. 遮罩盖住后、加载新场景前:`preload_group(新场景组)`
2. 新场景入场后:`release_group(旧场景组)`(与新组相同则保留,避免刚载又释放)

留空 `group` 的场景完全跳过这套流程(行为与 M1 一致)。

## Bus 事件

无。

## 依赖

- 依赖:`App.log`
- 初始化时机:Bootstrap 内核接线阶段挂在 App 下;阶段 5 预热 `&"core"` 组

## 持有的数据

- `_manifest`:统一清单实例(只用其 asset 条目);`_cache`:id → 已加载 Resource,进程生命周期(按组增删)

## 失败策略

- 未知 id:`get_asset` 记 error 返回 null
- 空组名/表未加载:`preload/release_group` 静默跳过

## 测试要点

- 已无头验证(2026-07-04):core 组启动预热、`get_asset` 缓存命中、未知 id 返回 null、release 后资源被回收(WeakRef 空)、**切场景时 level 组进场景预载/离场景释放、core 组始终保留**
- 后续单测(M6):按组加载的内存实测、并发预载去重、异步加载接入
