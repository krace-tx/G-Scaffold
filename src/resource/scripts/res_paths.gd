class_name ResPaths
extends RefCounted

## 框架硬编码的 res:// 资源文件路径集中地。
##
## 只收**物理文件路径**——各注册表 / 配置 .tres 的磁盘位置,供框架内部 load() 用。
## 与 ID 常量类(SceneIds / UIIds / AssetIds,存的是逻辑标识)分工不同,判断口诀:
## "我要哪个东西" → ID 常量;"这个文件在哪" → ResPaths。详见 docs/conventions/naming.md。
##
## 禁止在各 Service 里再写 const _XXX_PATH := "res://..." 的局部常量,一律登记到这里。

## 全项目唯一的资源清单(scene + ui + asset 三类条目合一)。三个 Service 都 load 它。
const MANIFEST: String = "res://src/resource/data/asset_manifest.tres"
