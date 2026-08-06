@tool
class_name RuntimeUIRegistry
extends Resource

## 运行时 UI 注册表,数据实例为 res://src/resource/data/ui_registry.tres。
##
## 由 Asset Groups 面板 Generate 从 [EditAssetManifest] 全量重建;运行时不得 load 本资源,
## 查表一律走生成的 [Uis] 常量类。

#region Exports & State
@export var entries: Array[RuntimeUIEntry] = []
#endregion
