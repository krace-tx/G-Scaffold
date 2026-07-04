class_name SceneIds
extends RefCounted

## 场景 id 常量集中地。代码里一律用 [code]SceneIds.XXX[/code],禁止裸字符串
## (见 docs/conventions/naming.md)。id 必须与 scene_registry.tres 里登记的
## [member SceneRegistryEntry.id] 完全一致,否则 SceneService 找不到场景。

const MAIN_MENU: StringName = &"main_menu"
const LEVEL: StringName = &"level"
