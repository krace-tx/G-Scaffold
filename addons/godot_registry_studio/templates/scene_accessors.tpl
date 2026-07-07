## 本场景关联的资产分组;未登记或无分组返回 &""。
static func asset_group(id: StringName) -> StringName:
	if not _TABLE.has(id):
		return &""
	return _TABLE[id].get("group", &"") as StringName
