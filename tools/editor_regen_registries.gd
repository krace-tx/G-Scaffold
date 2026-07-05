@tool
extends EditorScript

## 编辑器内一键重生成注册表常量类:脚本编辑器里打开本文件,File > Run
## (Ctrl+Shift+X)。等价的命令行/CI 入口见 generate_registries.tscn。

const _Codegen := preload("res://tools/registry_codegen.gd")

func _run() -> void:
	var result: Dictionary = _Codegen.run(false)
	for msg: String in result["errors"]:
		push_error(msg)
	print("regen registries: %d 个重写,%d 个已最新,%d 个错误" % [
		(result["written"] as Array).size(),
		(result["up_to_date"] as Array).size(),
		(result["errors"] as Array).size(),
	])
	if not (result["written"] as Array).is_empty():
		EditorInterface.get_resource_filesystem().scan()
