@tool
class_name RuntimeAssetEntry
extends Resource

## 运行时资产表的一条登记,由 [RegistryGenerator] 从 [EditAssetEntry] 生成。
##
## 存路径字符串而非 Resource 引用,避免 load 本表时把所有资产同步拉进内存。

#region Exports & State
@export var id: StringName = &""
@export var path: String = ""
@export var group: StringName = &""
#endregion
