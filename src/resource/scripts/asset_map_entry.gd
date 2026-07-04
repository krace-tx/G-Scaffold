class_name AssetMapEntry
extends Resource

## 资产表的一条记录:资产 id → 路径 + 所属分组。
## 由 [AssetMap] 持有一组,数据在 res://src/resource/data/asset_map.tres。
##
## 分组([member group])是按组预载/释放的单位:核心资产归 &"core"(常驻),
## 各场景/关卡的资产各归一组,进场景时预载、离场景时释放,控制内存峰值。

#region Exports & State
@export var id: StringName = &""
@export var path: String = ""
@export var group: StringName = &"core"
#endregion
