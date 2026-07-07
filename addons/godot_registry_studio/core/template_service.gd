@tool
class_name TemplateService
extends RefCounted

## 加载 [code]templates/[/code] 下的模板文件并填充 [code]{{PLACEHOLDER}}[/code] 占位符。

#region Constants & Enums
const PLACEHOLDER_OPEN := "{{"
const PLACEHOLDER_CLOSE := "}}"
const REGISTRY_TEMPLATE := "registry.tpl"
const COMMON_ACCESSORS_TEMPLATE := "common_accessors.tpl"
const GROUPS_BLOCK_TEMPLATE := "groups_block.tpl"
#endregion

#region Public API
## 返回模板根目录([member PluginConfig.plugin_path]/templates)。
static func templates_root() -> String:
	return PluginConfig.plugin_path().path_join("templates")


## 读取模板文件全文。返回 [RegistryResult]:成功时 [member RegistryResult.value] 为文本。
static func load_text(p_filename: String) -> RegistryResult:
	var path := templates_root().path_join(p_filename)
	if not FileAccess.file_exists(path):
		return RegistryResult.err("模板不存在: %s" % path)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return RegistryResult.err("读取模板失败(%d): %s" % [FileAccess.get_open_error(), path])
	return RegistryResult.ok(file.get_as_text())


## 用 [param p_vars] 替换 [param p_template] 中的 [code]{{KEY}}[/code] 占位符。
static func render(p_template: String, p_vars: Dictionary) -> String:
	var out := p_template
	for key: String in p_vars:
		out = out.replace(PLACEHOLDER_OPEN + key + PLACEHOLDER_CLOSE, String(p_vars[key]))
	return out
#endregion
