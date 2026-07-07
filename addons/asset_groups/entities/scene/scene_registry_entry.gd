@tool
class_name SceneRegistryEntry
extends Resource

## 运行时场景注册表的一条登记,由 [RegistryGenerator] 从 [SceneEntry] 生成。
##
## 存路径字符串而非 PackedScene 引用,避免 load 本表时把所有场景同步拉进内存。
## 业务代码经生成的 [Scenes] 常量类查表(uid 加载键),由 [SceneService] 按需异步加载。

#region Exports & State
@export var id: StringName = &""
@export var scene_path: String = ""
## 本场景关联的资产分组(可空)。SceneService 切入前预载、离开后释放。
@export var asset_group: StringName = &""
#endregion
