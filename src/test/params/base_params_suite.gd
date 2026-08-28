class_name BaseParamsSuite
extends TestSuite

## BaseParams 通用契约基类全类型互转综合测试集。
## 一个用例包揽所有数据类型（标量、引擎结构体、数组/字典容器、嵌套 BaseParams、自定义 Resource 实体、Resource 引用）。
## 验证从 Dictionary ➔ 强类型 Params ➔ to_dict() 互转后，没有任何参数被吞掉，并打印输出字典。

#region Mock Parameter Classes
class NestedSubParams extends BaseParams:
	var sub_id: int = 999
	var sub_name: String = "nested_default"
	var sub_weight: float = 1.0


class AllTypesCompositeParams extends BaseParams:
	# 1. 基础标量类型 (带宽松容错转换)
	var int_val: int = 0
	var float_val: float = 0.0
	var bool_val: bool = false
	var str_val: String = ""

	# 2. Godot 引擎数学结构体与 Color
	var vec2_val: Vector2 = Vector2.ZERO
	var vec3_val: Vector3 = Vector3.ZERO
	var color_val: Color = Color.BLACK
	var rect2_val: Rect2 = Rect2()

	# 3. 复合容器类型
	var str_list: Array[String] = []
	var int_list: Array[int] = []
	var meta_map: Dictionary = {}

	# 4. 嵌套 BaseParams 实体
	var sub_params: NestedSubParams = NestedSubParams.new()

	# 5. 自定义 Resource 业务实体 (如 AssetEntry)
	var asset_entry: AssetEntry = AssetEntry.new()

	# 6. 内存 Resource 引用
	var custom_resource: Resource = null

	# 7. 包含 BaseParams 对象的数组
	var sub_params_list: Array = []
#endregion


#region Lifecycle
func id() -> String:
	return "BaseParamsSuite"


func run(_host: Node) -> Result:
	await run_case("test_all_types_roundtrip_conversion", test_all_types_roundtrip_conversion)
	return outcome()
#endregion


#region Test Cases
## 全类型互转与防吞参数综合测试
func test_all_types_roundtrip_conversion() -> Result:
	var dummy_res := Resource.new()
	var sub_item1 := NestedSubParams.new({ "sub_id": 101, "sub_name": "list_item_1" })
	var sub_item2 := NestedSubParams.new({ "sub_id": 102, "sub_name": "list_item_2" })

	# 1. 构造包含全类型数据的输入字典
	var raw_input: Dictionary = {
		# 标量（故意传入需要宽松转换的类型测试兼容性）
		"int_val": "10086",			# String ➔ int
		"float_val": "3.14159",		# String ➔ float
		"bool_val": 1,				# int ➔ bool
		"str_val": 888888,			# int ➔ String

		# 引擎结构体
		"vec2_val": Vector2(1920, 1080),
		"vec3_val": Vector3(10.0, 20.0, 30.0),
		"color_val": Color(1.0, 0.4, 0.2, 0.9),
		"rect2_val": Rect2(100, 200, 300, 400),

		# 复合容器
		"str_list": ["gallery", "puzzle", "jigsaw"],
		"int_list": [10, 20, 30, 40, 50],
		"meta_map": {
			"platform": "ios",
			"quality": "high",
			"cache_version": 2
		},

		# 嵌套 BaseParams 字典
		"sub_params": {
			"sub_id": 777,
			"sub_name": "nested_hero",
			"sub_weight": 88.5
		},

		# 自定义 Resource 实体 (AssetEntry)
		"asset_entry": {
			"key": "theme_cover_01",
			"type": 0,
			"url": "https://cdn.jigsaw.com/theme_01.png",
			"md5": "e10adc3949ba59abbe56e057f20f883e",
			"folder": "themes/0",
			"filename": "cover.png",
			"is_required": true
		},

		# 内存 Resource 实例引用
		"custom_resource": dummy_res,

		# 包含 BaseParams 对象的数组
		"sub_params_list": [sub_item1, sub_item2]
	}

	# 2. 从 Dictionary 实例化为强类型 Params 对象
	var p := AllTypesCompositeParams.new(raw_input)

	# 3. 逐一验证强类型属性是否正确解析（防止参数被吞）
	if p.int_val != 10086:
		return Result.err("[int_val] was swallowed or parsed incorrectly: %s" % str(p.int_val))
	if not is_equal_approx(p.float_val, 3.14159):
		return Result.err("[float_val] was swallowed or parsed incorrectly: %s" % str(p.float_val))
	if p.bool_val != true:
		return Result.err("[bool_val] was swallowed or parsed incorrectly: %s" % str(p.bool_val))
	if p.str_val != "888888":
		return Result.err("[str_val] was swallowed or parsed incorrectly: %s" % str(p.str_val))

	if p.vec2_val != Vector2(1920, 1080):
		return Result.err("[vec2_val] mismatch.")
	if p.vec3_val != Vector3(10.0, 20.0, 30.0):
		return Result.err("[vec3_val] mismatch.")
	if p.color_val != Color(1.0, 0.4, 0.2, 0.9):
		return Result.err("[color_val] mismatch.")
	if p.rect2_val != Rect2(100, 200, 300, 400):
		return Result.err("[rect2_val] mismatch.")

	var expected_str_list: Array[String] = ["gallery", "puzzle", "jigsaw"]
	if p.str_list != expected_str_list:
		return Result.err("[str_list] array data was swallowed.")

	var expected_int_list: Array[int] = [10, 20, 30, 40, 50]
	if p.int_list != expected_int_list:
		return Result.err("[int_list] array data was swallowed.")
	if p.meta_map.get("platform") != "ios" or p.meta_map.get("cache_version") != 2:
		return Result.err("[meta_map] dictionary data was swallowed.")

	# 嵌套 BaseParams 校验
	if p.sub_params == null or p.sub_params.sub_id != 777 or p.sub_params.sub_name != "nested_hero":
		return Result.err("[sub_params] nested BaseParams was swallowed.")

	# 自定义 Resource 实体 (AssetEntry) 校验
	if p.asset_entry == null or not (p.asset_entry is AssetEntry):
		return Result.err("[asset_entry] was not decoded into AssetEntry.")
	if p.asset_entry.key != "theme_cover_01" or p.asset_entry.is_required != true:
		return Result.err("[asset_entry] fields were swallowed.")

	# Resource 引用校验
	if p.custom_resource != dummy_res:
		return Result.err("[custom_resource] Resource reference was swallowed.")

	# 4. 导出为 Dictionary 并进行输出打印
	var exported_dict := p.to_dict()

	print("\n==================== [BaseParams 全类型导出 Dictionary] ====================")
	for k in exported_dict:
		print("  • %-16s => %s" % [k, str(exported_dict[k])])
	print("============================================================================\n")

	# 5. 校验 to_dict() 导出的关键数据完整性
	var exp_entry: Dictionary = exported_dict.get("asset_entry", {})
	if exp_entry.get("key") != "theme_cover_01" or exp_entry.get("is_required") != true:
		return Result.err("[asset_entry] encode in to_dict() was swallowed.")

	var exp_sub: Dictionary = exported_dict.get("sub_params", {})
	if exp_sub.get("sub_id") != 777 or exp_sub.get("sub_name") != "nested_hero":
		return Result.err("[sub_params] recursion in to_dict() was swallowed.")

	var exp_sub_list: Array = exported_dict.get("sub_params_list", [])
	if exp_sub_list.size() != 2 or exp_sub_list[0].get("sub_id") != 101:
		return Result.err("[sub_params_list] Array[BaseParams] recursion was swallowed.")

	return Result.ok("All types roundtrip passed without swallowing any parameters.")
#endregion
