extends Node

## 注册表代码生成入口(无头/CI)。作为主场景运行(而非 --script),这样
## autoload 与全局类都会加载,codegen 引用的注册表脚本才能正常编译。
##
## 生成:godot --headless --path . res://tools/generate_registries.tscn
## 校验:godot --headless --path . res://tools/generate_registries.tscn -- check
## 退出码 = 错误数 + 过期文件数(0 = 生成物与注册表一致)。

const _Codegen := preload("res://tools/registry_codegen.gd")

func _ready() -> void:
	var check_only: bool = OS.get_cmdline_user_args().has("check")
	var result: Dictionary = _Codegen.run(check_only)
	for msg: String in result["errors"]:
		print("  ERROR %s" % msg)
	for path: String in result["stale"]:
		print("  STALE %s(注册表改了但没重新生成)" % path)
	for path: String in result["written"]:
		print("  WROTE %s" % path)
	for path: String in result["up_to_date"]:
		print("  OK    %s" % path)
	var failures: int = (result["errors"] as Array).size() + (result["stale"] as Array).size()
	print("=== generate_registries%s: %s ===" % [" (check)" if check_only else "", "OK" if failures == 0 else "%d PROBLEM(S)" % failures])
	get_tree().quit(failures)
