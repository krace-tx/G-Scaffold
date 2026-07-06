class_name SceneEntry
extends Resource

## 清单里的一条场景记录:场景 id → 场景文件路径 + 关联资产分组。
##
## 由 [AssetManifest] 的 [member AssetManifest.scenes] 持有一组。故意存路径字符串
## 而不是直接导出 PackedScene——后者会在清单被加载时就同步加载所有场景,而
## SceneService 需要按需 [code]load_threaded_request[/code] 异步加载,只有存路径
## 才能延迟到真正切换时才去读盘。
##
## 通过编辑器插件(res://addons/asset_groups/)可视化增删,不建议在 Inspector 里手改。

#region Exports & State
@export var id: StringName = &""
@export var scene_path: String = ""
## 进入本场景前要预载、离开后要释放的资产分组(可空)。取值须是某些
## [AssetEntry] 的 [member AssetEntry.group]。留空表示本场景不走分组预载。
@export var group: StringName = &""
#endregion
