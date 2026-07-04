class_name UIIds
extends RefCounted

## UI id 常量集中地。代码里一律用 [code]UIIds.XXX[/code],禁止裸字符串
## (见 docs/conventions/naming.md)。id 必须与 ui_registry.tres 里登记的
## [member UIRegistryEntry.id] 完全一致,否则 UIService 找不到界面。

const SETTINGS: StringName = &"settings"
