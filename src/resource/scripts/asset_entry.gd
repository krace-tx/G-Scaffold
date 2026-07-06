class_name AssetEntry
extends Resource

## 清单里的一条资产记录:资产 id → 路径 + 所属分组。
## 由 [AssetManifest] 的 [member AssetManifest.assets] 持有一组。
##
## 分组([member group])是按组预载/释放的内存单位:核心资产归 &"core"(常驻),
## 各场景/关卡的资产各归一组,进场景时预载、离场景时释放,控制内存峰值。
## 场景通过 [member SceneEntry.group] 声明自己进场时要预载哪一组。
##
## 通过编辑器插件(res://addons/asset_groups/)可视化增删,不建议在 Inspector 里手改。

#region Exports & State
@export var id: StringName = &""
@export var path: String = ""
@export var group: StringName = &"core"
#endregion
