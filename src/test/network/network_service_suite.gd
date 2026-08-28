class_name NetworkServiceSuite
extends TestSuite

## 用 Google 公共 HTTP API 冒烟测 [NetworkService]；须能上网。

#region Constants
## Google Public DNS over HTTPS（无需 key，返回 JSON）。
const _DNS_URL := "https://dns.google/resolve?name=example.com&type=A"
## gstatic 小图，测 download。
const _LOGO_URL := "https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_92x30dp.png"
const _LOGO_SAVE := "user://test_google_logo.png"
#endregion


#region Lifecycle
func id() -> String:
	return "NetworkService"


func run(_host: Node) -> Result:
	await run_case("test_dns_get", test_dns_get)
	await run_case("test_logo_download", test_logo_download)
	return outcome()
#endregion

#region Tests
## GET dns.google，校验 Status==0。
func test_dns_get() -> Result:
	var res: Result = await App.net.get_request(_DNS_URL)
	if res.is_err() or res.value == null:
		return Result.err("GET failed: %s." % res.error)

	var data: Dictionary = res.value as Dictionary
	var status: int = int(data.get("Status", -1))
	if status != 0:
		return Result.err("DNS Status is %d." % status)

	var answers: Array = data.get("Answer", []) as Array
	return Result.ok("Status=%d answers=%d" % [status, answers.size()])


## 下载 Google logo 到 user://，校验文件存在且非空。
func test_logo_download() -> Result:
	if FileAccess.file_exists(_LOGO_SAVE):
		DirAccess.remove_absolute(_LOGO_SAVE)

	var res: Result = await App.net.download_file(_LOGO_URL, _LOGO_SAVE)
	if res.is_err():
		return Result.err("Download failed: %s." % res.error)

	if not FileAccess.file_exists(_LOGO_SAVE):
		return Result.err("File missing at %s." % _LOGO_SAVE)

	var f := FileAccess.open(_LOGO_SAVE, FileAccess.READ)
	if f == null:
		return Result.err("Could not open %s." % _LOGO_SAVE)
	var bytes: int = f.get_length()
	f.close()
	if bytes <= 0:
		return Result.err("Downloaded file is empty.")

	DirAccess.remove_absolute(_LOGO_SAVE)
	return Result.ok("%s  %d bytes" % [_LOGO_SAVE, bytes])
#endregion
