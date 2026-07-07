class_name AssetIds
extends RefCounted

## 资产 id 常量集中地。代码一律用 [code]AssetIds.XXX[/code],禁止裸路径
## (见 docs/conventions/naming.md)。id 必须与 asset_map.tres 里登记的
## [member AssetMapEntry.id] 一致,否则 AssetService 找不到资产。
