@tool
class_name ResourceGroupConstants
extends RefCounted

const UNGROUPED_LABEL := "— ungrouped —"           # 未分组项目的显示标签
const NONE_GROUP_ITEM := "— none —"                # "无分组"选项的显示标签
const NO_GROUP_SELECTED := &"__none__"             # 表示"未选择分组"的哨兵指针
const GROUP_META_KIND := &"group"                  # 分组元数据的类型标识
const DEFAULT_NEW_RESOURCE_ID_BASE := "new_resource"     # 自动生成资源ID时的默认前缀
