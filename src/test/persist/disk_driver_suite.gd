class_name DiskDriverSuite
extends TestSuite

## 磁盘驱动与原子备份自愈机制测试集。
## 验证：
## 1. 原子写入与旧版本 .bak 自动备份；
## 2. 主文件损坏（非合法 JSON）时的自动容灾自愈；
## 3. 物理删除时的安全级联清理（.bak / .tmp 一并删除）；
## 4. 二进制 FILE 模式读写与 MD5 校验。

const TEST_PATH := "user://data/test_persist_sample.json"
const TEST_BIN_PATH := "user://cache/test_sample.bin"

var _driver := DiskDriver.new()


#region Lifecycle
func id() -> String:
	return "DiskDriverSuite"


func run(_host: Node) -> Result:
	await run_case("test_atomic_write_and_backup", test_atomic_write_and_backup)
	await run_case("test_self_healing_on_corruption", test_self_healing_on_corruption)
	await run_case("test_cascade_delete", test_cascade_delete)
	await run_case("test_binary_file_payload", test_binary_file_payload)
	_cleanup()
	return outcome()
#endregion


#region Tests
## 1. 测试写入新版本时，旧数据自动进 .bak 备份
func test_atomic_write_and_backup() -> Result:
	_cleanup()

	# 写入第 1 版数据
	var v1_data := {"version": 1, "name": "initial"}
	var res1 := _driver.write(TEST_PATH, v1_data)
	if res1.is_err():
		return Result.err("Write v1 failed: %s" % res1.error)

	# 验证主文件存在，且内容为 v1
	var read1 := _driver.read(TEST_PATH)
	if read1.is_err() or int(read1.value.get("version", 0)) != 1:
		return Result.err("Read v1 mismatch.")

	# 写入第 2 版数据
	var v2_data := {"version": 2, "name": "updated"}
	var res2 := _driver.write(TEST_PATH, v2_data)
	if res2.is_err():
		return Result.err("Write v2 failed: %s" % res2.error)

	# 验证主文件已升级为 v2
	var read2 := _driver.read(TEST_PATH)
	if read2.is_err() or int(read2.value.get("version", 0)) != 2:
		return Result.err("Read v2 mismatch.")

	# 验证 .bak 备份文件存在，且保留了 v1 的好数据
	var bak_path := TEST_PATH + ".bak"
	if not FileUtils.file_exists(bak_path):
		return Result.err("Backup file .bak does not exist.")

	var bak_read := FileUtils.read_json(bak_path)
	if bak_read.is_err() or int(bak_read.value.get("version", 0)) != 1:
		return Result.err("Backup content mismatch: expected v1.")

	return Result.ok("v1 backed up, v2 active.")


## 2. 测试主文件损坏时，自动从 .bak 恢复自愈
func test_self_healing_on_corruption() -> Result:
	# 前置确保有 v2 主文件和 v1 备份
	var bak_path := TEST_PATH + ".bak"
	if not FileUtils.file_exists(bak_path):
		_driver.write(TEST_PATH, {"version": 1})
		_driver.write(TEST_PATH, {"version": 2})

	# 人为破坏主文件（模拟写入断电导致的非法残缺 JSON）
	var corrupt_res := FileUtils.write_text(TEST_PATH, "{invalid_corrupted_json_content...")
	if corrupt_res.is_err():
		return Result.err("Failed to inject corrupted file.")

	# 尝试通过驱动读取（应当自动从 .bak 自愈并成功返回 v1）
	var heal_read := _driver.read(TEST_PATH)
	if heal_read.is_err():
		return Result.err("Self-healing failed: %s" % heal_read.error)

	var recovered_version := int(heal_read.value.get("version", 0))
	if recovered_version != 1:
		return Result.err("Self-healing data mismatch: expected v1, got %d" % recovered_version)

	# 验证主文件是否已被自愈修复为合法 JSON
	var primary_repaired := FileUtils.read_json(TEST_PATH)
	if primary_repaired.is_err():
		return Result.err("Primary file was not repaired after self-healing.")

	return Result.ok("Recovered version=%d successfully." % recovered_version)


## 3. 测试物理删除时的级联安全清理
func test_cascade_delete() -> Result:
	# 准备主文件、.bak 与 .tmp
	_driver.write(TEST_PATH, {"version": 3})
	FileUtils.write_text(TEST_PATH + ".tmp", "temp_data")

	var del_res := _driver.delete(TEST_PATH)
	if del_res.is_err():
		return Result.err("Delete failed: %s" % del_res.error)

	# 验证主文件、.bak、.tmp 全部已被清空
	if FileUtils.file_exists(TEST_PATH):
		return Result.err("Primary file still exists after delete.")
	if FileUtils.file_exists(TEST_PATH + ".bak"):
		return Result.err("Backup file still exists after delete.")
	if FileUtils.file_exists(TEST_PATH + ".tmp"):
		return Result.err("Temp file still exists after delete.")

	return Result.ok("All related files cleaned.")


## 4. 测试二进制不透明文件写入与 MD5 校验
func test_binary_file_payload() -> Result:
	var raw_bytes := "funny_jigsaw_binary_payload_test".to_utf8_buffer()
	var expected_md5 := raw_bytes.hex_encode().md5_text()

	var write_res := _driver.write(TEST_BIN_PATH, raw_bytes, {"payload_type": "FILE"})
	if write_res.is_err():
		return Result.err("Binary write failed: %s" % write_res.error)

	# 校验读取
	var read_res := _driver.read(TEST_BIN_PATH, {
		"payload_type": "FILE",
		"expected_md5": FileAccess.get_md5(TEST_BIN_PATH),
	})
	if read_res.is_err():
		return Result.err("Binary read failed: %s" % read_res.error)

	var read_bytes := read_res.value as PackedByteArray
	if read_bytes != raw_bytes:
		return Result.err("Binary data content mismatch.")

	FileUtils.remove_file(TEST_BIN_PATH)
	return Result.ok("Binary read/write & MD5 verified.")
#endregion


#region Private Helpers
func _cleanup() -> void:
	_driver.delete(TEST_PATH)
	FileUtils.remove_file(TEST_BIN_PATH)
#endregion
