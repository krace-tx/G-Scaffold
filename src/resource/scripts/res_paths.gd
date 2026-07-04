class_name ResPaths
extends RefCounted

## 框架硬编码的 res:// 资源文件路径集中地。
##
## 只收**物理文件路径**——各注册表 / 配置 .tres 的磁盘位置,供框架内部 load() 用。
## 与 ID 常量类(SceneIds / UIIds / AssetIds,存的是逻辑标识)分工不同,判断口诀:
## "我要哪个东西" → ID 常量;"这个文件在哪" → ResPaths。详见 docs/conventions/naming.md。
##
## 禁止在各 Service 里再写 const _XXX_PATH := "res://..." 的局部常量,一律登记到这里。

const SCENE_REGISTRY: String = "res://src/resource/data/scene_registry.tres"
const UI_REGISTRY: String = "res://src/resource/data/ui_registry.tres"
const ASSET_MAP: String = "res://src/resource/data/asset_map.tres"
