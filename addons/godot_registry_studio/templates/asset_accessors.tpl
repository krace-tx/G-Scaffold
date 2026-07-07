## 资产所属分组;未登记返回 &""。
static func group(id: StringName) -> StringName:
	if not _TABLE.has(id):
		return &""
	return _TABLE[id].get("group", &"") as StringName


## 某分组内的全部资产 id(生成期预计算);无此分组返回空数组。
static func ids_in_group(group_name: StringName) -> Array[StringName]:
	return _GROUPS.get(group_name, []) as Array[StringName]
