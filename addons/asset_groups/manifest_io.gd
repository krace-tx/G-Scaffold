@tool
extends RefCounted

## 清单读写 + Ids 代码生成的纯逻辑层——把"编辑器面板"与"磁盘/代码产物"解耦。
##
## 面板只负责把用户输入收集进一个内存中的 [AssetManifest],真正落盘(.tres)与
## 生成 SceneIds/UIIds/AssetIds 常量类全部在这里完成,便于单独复用与测试。
## 刻意不依赖框架的 Result 等类型,保持插件自成一体、可整目录搬到别的项目。

#region Constants & Enums
## 三类条目 → 生成的 Ids 常量类信息:[类名, 文档里的中文名词, 输出文件名]。
const _IDS_JOBS: Array = [
	["scenes", "SceneIds", "场景", "scene_ids.gd"],
	["uis", "UIIds", "界面", "ui_ids.gd"],
	["assets", "AssetIds", "资产", "asset_ids.gd"],
]
#endregion

#region Public API
## 从 [param path] 读清单并返回一份**深拷贝**(隔离工作副本,编辑不污染引擎缓存);
## 文件不存在或类型不符时返回一个空的新 [AssetManifest]。
static func load_working_copy(path: String) -> AssetManifest:
	if ResourceLoader.exists(path):
		var res := ResourceLoader.load(path)
		if res is AssetManifest:
			return (res as AssetManifest).duplicate(true)
	return AssetManifest.new()


## 把 [param manifest] 保存为 .tres 到 [param path]。返回引擎 [enum Error](OK=0)。
static func save_manifest(manifest: AssetManifest, path: String) -> int:
	return ResourceSaver.save(manifest, path)


## 依据 [param manifest] 生成三份 Ids 常量类到 [param ids_dir]。任一文件写失败即返回
## 该错误码并中止;全部成功返回 OK。会整体重写目标文件(不做合并)。
static func generate_ids(manifest: AssetManifest, ids_dir: String) -> int:
	for job: Array in _IDS_JOBS:
		var ids := _collect_ids(manifest.get(job[0]))
		var text := _ids_source(job[1], job[2], ids)
		var err := _write_text(ids_dir.path_join(job[3]), text)
		if err != OK:
			return err
	return OK


## 导出前的一致性校验:返回问题清单(空数组 = 通过)。检查每类条目的 id/路径是否
## 为空、以及同类内 id 是否重复——这些都会让运行期 Service 找不到目标或行为诡异。
static func validate(manifest: AssetManifest) -> PackedStringArray:
	var problems := PackedStringArray()
	_validate_group(manifest.scenes, "scene", "scene_path", problems)
	_validate_group(manifest.uis, "ui", "scene_path", problems)
	_validate_group(manifest.assets, "asset", "path", problems)
	return problems
#endregion

#region Internal
static func _collect_ids(entries: Array) -> Array:
	var out: Array = []
	for entry: Resource in entries:
		out.append(entry.id)
	return out


## 生成单个 Ids 常量类的完整源码。格式与仓库现有 *_ids.gd 保持一致,确保重复导出
## 幂等、diff 干净。id 直接作常量值,大写形式作常量名(约定 id 均为合法 snake 标识符)。
static func _ids_source(cls: String, noun: String, ids: Array) -> String:
	var lines := PackedStringArray()
	lines.append("class_name %s" % cls)
	lines.append("extends RefCounted")
	lines.append("")
	lines.append("## %s id 常量集中地(自动生成,请勿手改)。" % noun)
	lines.append("## 由 res://addons/asset_groups/ 导出时,依据 asset_manifest.tres 整体重写。")
	lines.append("## 代码里一律用 %s.XXX,禁止裸字符串;详见 docs/conventions/naming.md。" % cls)
	lines.append("")
	for id: StringName in ids:
		lines.append("const %s: StringName = &\"%s\"" % [String(id).to_upper(), id])
	return "\n".join(lines) + "\n"


static func _write_text(path: String, text: String) -> int:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(text)
	file.close()
	return OK


static func _validate_group(entries: Array, kind: String, path_key: String, problems: PackedStringArray) -> void:
	var seen: Dictionary = {}
	for i in entries.size():
		var entry: Resource = entries[i]
		var id := String(entry.id)
		if id.is_empty():
			problems.append("%s #%d 的 id 为空" % [kind, i + 1])
		elif seen.has(id):
			problems.append("%s id 重复:'%s'" % [kind, id])
		else:
			seen[id] = true
		if String(entry.get(path_key)).is_empty():
			problems.append("%s '%s' 的路径为空" % [kind, id if not id.is_empty() else "#%d" % (i + 1)])
#endregion
