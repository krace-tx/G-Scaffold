class_name AssetServiceSuite
extends TestSuite

## 只测 [MemoryUtils.inspect] 对 [code]res://icon.png[/code] 的显存估算。

#region Constants
const _ICON := "res://icon.png"
#endregion


#region Lifecycle
func id() -> String:
	return "AssetService"


func run(_host: Node) -> Result:
	await run_case("test_icon_vram", test_icon_vram)
	return outcome()
#endregion

#region Tests
## 加载 icon，用 MemoryUtils 估算显存占用并打在 detail 里。
func test_icon_vram() -> Result:
	var loaded: Result = await App.asset.load(_ICON)
	if loaded.is_err() or loaded.value == null:
		return Result.err("Load icon failed: %s." % loaded.error)

	var info := MemoryUtils.inspect(loaded.value as Resource)
	if not info.known:
		return Result.err("MemoryUtils could not estimate %s." % String(info.type))
	var bytes: int = int(info.bytes)
	if bytes <= 0:
		return Result.err("Estimated VRAM is %d bytes." % bytes)
	return Result.ok("%s  %s  %d bytes (%.2f KB)" % [
		_ICON,
		String(info.type),
		bytes,
		bytes / 1024.0,
	])
#endregion
