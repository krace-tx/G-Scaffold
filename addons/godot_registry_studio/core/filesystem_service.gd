@tool
class_name FilesystemService
extends RefCounted

## 注册表与生成物的磁盘读写,以及编辑器资源文件系统刷新。

#region Public API
## 加载 [param p_path] 处的 Resource。返回 [RegistryResult]。
static func load_resource(p_path: String) -> RegistryResult:
	if not ResourceLoader.exists(p_path):
		return RegistryResult.err("资源不存在: %s" % p_path)
	var resource: Resource = load(p_path)
	if resource == null:
		return RegistryResult.err("加载失败: %s" % p_path)
	return RegistryResult.ok(resource)


## 将 [param p_resource] 保存到 [param p_path]。返回 [RegistryResult]。
static func save_resource(p_path: String, p_resource: Resource) -> RegistryResult:
	var err := ResourceSaver.save(p_resource, p_path)
	if err != OK:
		return RegistryResult.err("保存失败(%d): %s" % [err, p_path])
	return RegistryResult.ok()


## 将文本写入 [param p_path](用于代码生成落盘)。返回 [RegistryResult]。
static func write_text(p_path: String, p_content: String) -> RegistryResult:
	var file := FileAccess.open(p_path, FileAccess.WRITE)
	if file == null:
		return RegistryResult.err("写入失败(%d): %s" % [FileAccess.get_open_error(), p_path])
	file.store_string(p_content)
	file.close()
	return RegistryResult.ok()


## 通知编辑器资源文件系统刷新;[param p_path] 为空则全量扫描。
static func refresh(p_path: String = "") -> void:
	var filesystem: EditorFileSystem = EditorInterface.get_resource_filesystem()
	if filesystem == null:
		return
	if p_path.is_empty():
		filesystem.scan()
	else:
		filesystem.update_file(p_path)
#endregion
