extends Node

## 轻量无头单测运行器(不依赖 gdUnit4 插件,零依赖,CI 就绪)。
##
## 运行:godot --headless res://tools/tests/test_runner.tscn
## 退出码 = 失败数(0 = 全绿)。作为主场景启动,autoload(App/Bus)会被加载,
## 因此引用了 App 的类(SaveService/ConfigService)也能正常编译——但本运行器只
## 调用它们**不碰 App 的纯逻辑方法**,不依赖 Bootstrap 真正跑起来。
##
## 为什么不用 --script:那种模式不加载 autoload,凡在文件作用域引用 App 的类会
## 直接编译失败(标识符 App 未定义),导致 SaveService/ConfigService 整个不可用。
##
## 覆盖:Result、SaveService 迁移、ConfigService 合并、TimeService 偏移。

## 期望执行的断言总数。实际执行数对不上说明有测试方法中途抛错被跳过(GDScript
## 无 try/catch,靠这个哨兵把"静默跳过"暴露成失败,避免假绿)。
const _EXPECTED_CHECKS: int = 22

var _failed: int = 0
var _ran: int = 0

func _ready() -> void:
	_test_result()
	_test_save_migrations()
	_test_config_merge()
	_test_time_service()

	if _ran != _EXPECTED_CHECKS:
		print("  FAIL sentinel: ran %d checks, expected %d (a test method threw?)" % [_ran, _EXPECTED_CHECKS])
		_failed += 1
	print("=== unit tests: %s (%d checks) ===" % ["ALL PASS" if _failed == 0 else "%d FAIL" % _failed, _ran])
	get_tree().quit(_failed)


func _test_result() -> void:
	print("[Result]")
	var ok := Result.ok(42)
	_check("ok is_ok", ok.is_ok())
	_check("ok not is_err", not ok.is_err())
	_check("ok value", ok.value == 42)
	var err := Result.err("boom")
	_check("err is_err", err.is_err())
	_check("err error", err.error == "boom")
	_check("value_or on err returns default", err.value_or(7) == 7)
	_check("value_or on ok returns value", ok.value_or(7) == 42)


func _test_save_migrations() -> void:
	print("[SaveService migrations]")
	# 单表达式 lambda:d.merged({...}) 返回合并后的新字典(避免内联多语句 lambda)。
	var migrations := {
		1: func(d: Dictionary) -> Dictionary: return d.merged({"a": 1}),
		2: func(d: Dictionary) -> Dictionary: return d.merged({"b": 2}),
	}
	var full := SaveService._run_migrations({}, 1, 3, migrations)
	_check("migrated has a", full.get("a") == 1)
	_check("migrated has b", full.get("b") == 2)
	var partial := SaveService._run_migrations({}, 2, 3, migrations)
	_check("partial skips a", not partial.has("a"))
	_check("partial has b", partial.get("b") == 2)
	var noop := SaveService._run_migrations({"x": 9}, 3, 3, migrations)
	_check("noop unchanged", noop.get("x") == 9 and noop.size() == 1)
	var gap := SaveService._run_migrations({}, 1, 4, {1: migrations[1]})
	_check("gap tolerates missing migration", gap.get("a") == 1)


func _test_config_merge() -> void:
	print("[ConfigService merge]")
	var cfg := ConfigService.new()
	cfg.set_defaults({"gold": 100, "ads": true, "vip": false})
	cfg._local = {"gold": 200}     # 直接设内部层,避免 apply_remote 触发 App.log
	cfg._remote = {"gold": 300}
	_check("remote wins over local/default", cfg.get_int("gold") == 300)
	_check("default when no override", cfg.get_bool("ads") == true)
	cfg._remote = {}
	_check("local wins when no remote", cfg.get_int("gold") == 200)
	cfg._local = {}
	_check("default when no remote/local", cfg.get_int("gold") == 100)
	_check("fallback when missing everywhere", cfg.get_string("nope", "x") == "x")


func _test_time_service() -> void:
	print("[TimeService]")
	var t := TimeService.new()
	_check("untrusted before sync", not t.is_trusted())
	var sys := t.now()
	_check("untrusted now ~ system clock", absi(sys - int(Time.get_unix_time_from_system())) <= 2)
	t.sync_from_server(4_000_000_000 * 1000)
	_check("trusted after sync", t.is_trusted())
	_check("now uses server anchor", t.now() >= 4_000_000_000)


func _check(name: String, cond: bool) -> void:
	_ran += 1
	print(("  PASS " if cond else "  FAIL ") + name)
	if not cond:
		_failed += 1
