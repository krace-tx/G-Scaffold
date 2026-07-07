@tool
class_name AssetMapEntry
extends Resource

## 运行时资产表的一条登记,由 [RegistryGenerator] 从 [AssetEntry] 生成。
##
## 存路径字符串而非 Resource 引用,避免 load 本表时把所有资产同步拉进内存。
## 业务代码经生成的 [Assets] 常量类查表,由 [AssetService] 按需加载。

#region Exports & State
@export var id: StringName = &""
@export var path: String = ""
## 按组预载/释放的单位;核心资产归 &"core"(常驻),各场景/关卡各归一组。
@export var group: StringName = &"core"
#endregion
