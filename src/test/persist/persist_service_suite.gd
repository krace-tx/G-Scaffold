class_name PersistServiceSuite
extends TestSuite

## 用 [User] 实体 bind 后测 write / read。

#region Lifecycle
func id() -> String:
	return "PersistService"


func run(_host: Node) -> Result:
	await run_case("test_user_bind_write_read", test_user_bind_write_read)
	return outcome()
#endregion

#region Tests
## bind User 的 StorageItem，写入后再读回。
func test_user_bind_write_read() -> Result:
	var user := User.new()
	user.id = "u_1"
	user.nickname = "alice"

	var item := User.storage_item()

	var persist := PersistService.new()
	persist.bind(item)

	var written: Result = await persist.write_async(item, user.encode())
	if written.is_err():
		return Result.err("Write failed: %s." % written.error)

	var loaded: Result = await persist.read_async(item)
	if loaded.is_err() or loaded.value == null:
		return Result.err("Read failed: %s." % loaded.error)

	var restored := User.decode(loaded.value as Dictionary)
	if restored == null or restored.nickname != "alice":
		return Result.err("Read mismatch: %s." % str(loaded.value))

	if FileAccess.file_exists(item.disk_path):
		DirAccess.remove_absolute(item.disk_path)
	return Result.ok("id=%s nickname=%s" % [restored.id, restored.nickname])
#endregion
