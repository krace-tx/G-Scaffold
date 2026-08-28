class_name SettingManager
extends RefCounted

## 游戏设置业务管理器。
## 持有并管理 [GameSetting] 纯数据实体，协调底层引擎生效（音频静音、触觉振动）、异步持久化与外链跳转。

signal changed ## 设置项发生变动时触发

var data: GameSetting = GameSetting.new()


#region Toggles & Vibration
## 背景音乐（BGM）开关状态；修改时自动应用到音频服务并异步存盘
var music_on: bool:
	get:
		return data.music_on
	set(value):
		if data.music_on == value:
			return
		data.music_on = value
		_apply_audio()
		save_async()
		changed.emit()

## 游戏音效（SFX）开关状态；修改时自动应用到音频服务并异步存盘
var sfx_on: bool:
	get:
		return data.sfx_on
	set(value):
		if data.sfx_on == value:
			return
		data.sfx_on = value
		_apply_audio()
		save_async()
		changed.emit()

## 设备触觉振动反馈开关状态；修改时自动异步存盘
var vibrate_on: bool:
	get:
		return data.vibrate_on
	set(value):
		if data.vibrate_on == value:
			return
		data.vibrate_on = value
		save_async()
		changed.emit()


## 切换背景音乐开关。[br]
## 返回切换后的最新开启状态（true 为开启，false 为关闭）。
func toggle_music() -> bool:
	music_on = not music_on
	return music_on


## 切换游戏音效开关。[br]
## 返回切换后的最新开启状态（true 为开启，false 为关闭）。
func toggle_sfx() -> bool:
	sfx_on = not sfx_on
	return sfx_on


## 切换触觉振动开关。[br]
## 返回切换后的最新开启状态（true 为开启，false 为关闭）。
func toggle_vibrate() -> bool:
	vibrate_on = not vibrate_on
	return vibrate_on


## 触发一次设备触觉振动反馈（仅在 [member vibrate_on] 为 true 时生效）。[br]
## [param duration_ms]：振动持续时间（毫秒），默认 40ms。
func vibrate(duration_ms: int = 40) -> void:
	if data.vibrate_on:
		Input.vibrate_handheld(duration_ms)
#endregion


#region External Links
## 在系统默认浏览器中打开隐私协议网页。
func open_privacy_policy() -> void:
	_open_url(data.privacy_policy_url, "Privacy Policy")


## 在系统默认浏览器中打开服务条款网页。
func open_terms_of_service() -> void:
	_open_url(data.terms_of_service_url, "Terms of Service")


## 在系统默认浏览器中打开联系客服/意见反馈网页。
func open_contact_us() -> void:
	_open_url(data.contact_us_url, "Contact Us")
#endregion


#region Persistence & Lifecycle
## 手动将当前内存中的偏好设置全面应用到引擎底层（音频总线静音状态等）。
func apply_all() -> void:
	_apply_audio()


## 异步将当前设置数据保存到本地持久化磁盘文件。
func save_async() -> void:
	if App.persist != null:
		await App.persist.write_async(GameSetting.storage_item(), data.encode(), WriteMode.LOCAL_ONLY)


## 异步从本地磁盘加载设置存档（若无存档则保留默认设置），并立即将状态应用到引擎底层。
func load_async() -> Result:
	var item := GameSetting.storage_item()
	if App.persist != null:
		App.persist.bind(item)
		var res: Result = await App.persist.read_async(item, ReadMode.LOCAL_ONLY)
		if res.is_ok() and res.value is Dictionary:
			var loaded := GameSetting.decode(res.value as Dictionary)
			if loaded != null:
				data = loaded
	apply_all()
	return Result.ok()
#endregion


#region Internal
## 将当前音频开关同步到底层的 [AudioService]。
func _apply_audio() -> void:
	if App.audio != null:
		App.audio.set_music_enabled(data.music_on)
		App.audio.set_sfx_enabled(data.sfx_on)


## 安全调用系统原生能力打开外部 Web 链接。
func _open_url(url: String, tag: String = "") -> void:
	if url.is_empty():
		App.log.info("SettingManager", "%s URL is empty; skip opening." % tag)
		return
	OS.shell_open(url)
#endregion
