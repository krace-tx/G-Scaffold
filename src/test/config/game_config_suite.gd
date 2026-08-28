class_name GameConfigSuite
extends TestSuite

## 单测：发起真实 HTTP 请求拉取远端游戏配置，解码后打印 config（供人工核对后端对接）。

#region Lifecycle
func id() -> String:
	return "GameConfig"


func run(_host: Node) -> Result:
	await run_case("test_fetch_remote_print_config", test_fetch_remote_print_config)
	return outcome()
#endregion


#region Tests
## 真实请求远端配置接口 → [method GameConfig.decode] 解码 → 打印完整配置。
func test_fetch_remote_print_config() -> Result:
	var item := GameConfig.storage_item()
	var res: Result = await App.persist.read_async(item, ReadMode.REMOTE_ONLY)
	if res.is_err():
		return Result.err("fetch_remote failed: %s" % res.error)

	var dict := res.value as Dictionary
	if int(dict.get("code", -1)) != 200:
		return Result.err("Response code not 200: %s" % dict.get("msg", ""))
	var payload: Variant = dict.get("data", null)
	if not payload is Dictionary:
		return Result.err("Invalid response data")

	var config := GameConfig.decode(payload as Dictionary)
	if config == null:
		return Result.err("config is null after decode")

	# 打印配置：摘要 + 完整 JSON
	print("=== Remote GameConfig (server_version=%s, levels=%d, themes=%d, min_display_themes=%d) ===" % [
		config.server_version,
		config.level_config.levels.size(),
		config.level_config.themes.size(),
		config.level_config.min_display_theme_count,
	])
	print(JSON.stringify(config.encode(), "\t"))

	return Result.ok("server_version=%s levels=%d themes=%d" % [
		config.server_version,
		config.level_config.levels.size(),
		config.level_config.themes.size(),
	])
#endregion
