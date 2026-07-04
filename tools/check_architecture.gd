extends SceneTree

## 架构违规检查器(实现 docs/conventions/directory.md 的"违规引用清单")。
##
## 运行:godot --headless --script res://tools/check_architecture.gd
## 退出码 = 违规数(0 = 干净),可接 pre-commit / CI。
##
## 纯文本扫描(不需要 autoload,故用 --script),对 src/ 下的 .gd 逐行套规则。
## 规则见 RULES:每条 = 适用路径前缀 + 禁止的正则 + 说明。允许豁免特定文件
## (如 SceneService 内部允许 change_scene,注册表里允许资产路径)。

var _violations: int = 0

func _initialize() -> void:
	# 每条规则:{scope: 路径前缀, pattern: 正则, msg: 说明, allow: 豁免文件后缀数组}
	var rules: Array[Dictionary] = [
		{
			"scope": "res://src/framework/",
			"pattern": "res://src/game/",
			"msg": "framework 不得引用 game/(单向依赖,见 directory.md)",
			"allow": [],
		},
		{
			"scope": "res://src/framework/",
			"pattern": "res://src/platform/",
			"msg": "framework 不得引用 platform/(单向依赖)",
			"allow": [],
		},
		{
			"scope": "res://src/platform/",
			"pattern": "res://src/game/",
			"msg": "platform 不得引用 game/",
			"allow": [],
		},
		{
			"scope": "res://src/",
			"pattern": "get_tree\\(\\)\\.change_scene",
			"msg": "只有 SceneService 内部允许 change_scene(见 directory.md)",
			"allow": ["scene_service.gd"],
		},
		{
			"scope": "res://src/",
			"pattern": "\"res://src/assets/",
			"msg": "禁止裸 assets 路径字符串,须经 AssetService + asset_map",
			"allow": ["asset_map.tres"],
		},
	]

	var files := _collect_gd_files("res://src")
	for path in files:
		_check_file(path, rules)

	if _violations == 0:
		print("=== check_architecture: CLEAN (%d files scanned) ===" % files.size())
	else:
		print("=== check_architecture: %d VIOLATION(S) ===" % _violations)
	quit(_violations)


func _check_file(path: String, rules: Array[Dictionary]) -> void:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return
	var lines := text.split("\n")

	for rule: Dictionary in rules:
		if not path.begins_with(rule["scope"]):
			continue
		if _is_allowed(path, rule["allow"]):
			continue
		var re := RegEx.new()
		re.compile(rule["pattern"])
		for i in lines.size():
			if re.search(lines[i]) != null:
				_violations += 1
				print("  VIOLATION %s:%d — %s" % [path, i + 1, rule["msg"]])


func _is_allowed(path: String, allow: Array) -> bool:
	for suffix: String in allow:
		if path.ends_with(suffix):
			return true
	return false


## 递归收集目录下的 .gd 文件(.tres 也扫,用于 assets 路径规则)。
func _collect_gd_files(dir_path: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var full := dir_path.path_join(name)
		if dir.current_is_dir():
			out.append_array(_collect_gd_files(full))
		elif name.ends_with(".gd") or name.ends_with(".tres"):
			out.append(full)
		name = dir.get_next()
	dir.list_dir_end()
	return out
