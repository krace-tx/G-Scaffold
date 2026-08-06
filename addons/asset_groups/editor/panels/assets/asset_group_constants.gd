@tool
class_name AssetGroupConstants
extends RefCounted

## Assets 页共享常量:树、详情面板与总调度器统一引用,消灭裸魔法字符串。

const UNGROUPED_LABEL := "— ungrouped —"           # 未分组项目的显示标签
const NONE_GROUP_ITEM := "— none —"                # "无分组"选项的显示标签
const NO_GROUP_SELECTED := &"__none__"             # 表示"未选择分组"的哨兵指针
const GROUP_META_KIND := &"group"                  # 分组元数据的类型标识
const DEFAULT_NEW_ASSET_ID_BASE := "new_asset"     # 自动生成资产ID时的默认前缀
