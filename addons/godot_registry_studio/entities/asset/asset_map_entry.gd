class_name AssetMapEntry
extends Resource

## 资产表的一条登记:把资源文件拖进 [member asset] + 声明所属分组。
##
## 引用经 Godot UID 追踪,移动/改名不断链。id 默认取资源文件名,同一文件
## 登记多条(不同分组)时用 [member id_override] 区分。登记后由面板生成 [Assets] 常量类。
##
## 分组([member group])是按组预载/释放的单位:核心资产归 &"core"(常驻),
## 各场景/关卡的资产各归一组,进场景时预载、离场景时释放,控制内存峰值。

#region Constants & Enums
## Inspector 可拖入的资源类型(生成器只读路径/UID,运行时不加载本注册表)。
const _EXPORT_ASSET_TYPES := (
	"Texture2D,AudioStream,FontFile,Shader,ShaderMaterial,Material,"
	+ "PackedScene,Animation,Mesh,SpriteFrames,TileSet"
)
#endregion

#region Exports & State
## 直接拖资源文件进来。运行时由 AssetService 按需加载。
@export_custom(PROPERTY_HINT_RESOURCE_TYPE, _EXPORT_ASSET_TYPES) var asset: Resource = null

## 资产 id,留空则取资源文件名。
@export var id_override: StringName = &""

@export var group: StringName = &"core"
#endregion
