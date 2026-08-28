class_name TestApp
extends Node

## F6 运行本场景。结果打在 Output。

func _suites() -> Array[TestSuite]:
	return [
		BaseParamsSuite.new(),
		#DiskDriverSuite.new(),
		#PersistServiceSuite.new(),
		#GameConfigSuite.new(),
	]


func _ready() -> void:
	await TestPipeline.new(_suites()).run(self)
