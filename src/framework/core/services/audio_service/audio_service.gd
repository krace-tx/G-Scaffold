class_name AudioService
extends Node

## 音频服务：提供 BGM/SFX 分组总线音量控制、BGM 跨场景交叉淡变、SFX 播放器池复用功能。
##
## 建议全项目的音频播放均通过此服务调用，避免直接实例化 AudioStreamPlayer。
## 统一管理可确保音量分组生效、跨场景 BGM 无缝衔接以及播放器资源的有效复用。
##
## BGM 与 SFX 分别使用独立的音频总线（自动创建并路由至 Master），
## 以便在设置菜单中独立调节“音乐”与“音效”音量。
## 本服务需作为常驻节点（如挂载在 App 下），以保证 BGM 在场景切换时不中断。

#region Constants & Enums
const _BUS_MASTER: String = "Master"
const _BUS_BGM: String = "BGM"
const _BUS_SFX: String = "SFX"

const _SFX_POOL_SIZE: int = 8       ## SFX 并发播放上限,轮转复用
const _DEFAULT_FADE: float = 0.6    ## BGM 交叉淡变默认时长(秒)
const _SILENT_DB: float = -80.0     ## 视作静音的分贝值(≈线性 0)
const MIN_INTERVAL_MS: int = 30     ## 同音效最小播放间隔（毫秒）
#endregion

#region Exports & State
## 两个 BGM 播放器轮流做"当前/淡入"角色,实现真正的交叉淡变(旧的淡出同时新的淡入)。
var _bgm_players: Array[AudioStreamPlayer] = []
var _bgm_active: int = 0

## 当前正在进行的 BGM 交叉淡变 tween。新切换前先 kill 它,避免快速连切时旧淡变
## 的收尾 stop() 误杀新曲(fire-and-forget 竞态)。
var _bgm_tween: Tween

## SFX 播放器池,轮转使用,超过并发数会打断最早的那个(可接受)。
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_next: int = 0

## 音效专用播放器
var _sfx_player: AudioStreamPlayer

## 路径 -> 上次播放时间戳（毫秒）
var _last_played_times: Dictionary = {}

#endregion

#region Lifecycle
func _ready() -> void:
	_ensure_bus(_BUS_BGM)
	_ensure_bus(_BUS_SFX)

	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = _BUS_BGM
		NodeUtils.mount_required(p, self, "BGMPlayer_%d" % i)
		_bgm_players.append(p)

	for i in _SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = _BUS_SFX
		NodeUtils.mount_required(p, self, "SFXPlayer_%d" % i)
		_sfx_pool.append(p)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = _BUS_SFX
	NodeUtils.mount_required(_sfx_player, self, "GameStartPlayer")
#endregion

#region Public API
#region BGM Playback
## 播放背景音乐,与当前曲目交叉淡变。**同一曲目正在播放则不打断**(跨场景连续的关键)。
func play_bgm_by_path(path: String, volume: float = 0.0, fade: float = _DEFAULT_FADE) -> void:
	var stream: AudioStream = await load_audio(path)
	if stream == null:
		return

	# 确保背景音乐强制开启循环播放
	_ensure_stream_loop(stream)

	var active := _bgm_players[_bgm_active]
	if active.stream == stream and active.playing:
		return

	_kill_bgm_tween()
	var incoming := _bgm_players[1 - _bgm_active]
	incoming.stream = stream
	incoming.volume_db = _SILENT_DB
	incoming.play()

	_bgm_tween = create_tween().set_parallel(true)
	_bgm_tween.tween_property(active, "volume_db", _SILENT_DB, fade)
	_bgm_tween.tween_property(incoming, "volume_db", volume, fade)
	_bgm_tween.chain().tween_callback(active.stop)

	_bgm_active = 1 - _bgm_active


## 停止背景音乐(淡出)。
func stop_bgm(fade: float = _DEFAULT_FADE) -> void:
	var active := _bgm_players[_bgm_active]
	if not active.playing:
		return
	_kill_bgm_tween()
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(active, "volume_db", _SILENT_DB, fade)
	_bgm_tween.tween_callback(active.stop)
#endregion


#region SFX Playback
## 播放指定路径的音效，包含同音抑制和分贝调节。
func play_sfx_by_path(path: String, volume: float = 0.0) -> void:
	var now := Time.get_ticks_msec()
	if _last_played_times.has(path) and (now - _last_played_times[path] < MIN_INTERVAL_MS):
		return
	_last_played_times[path] = now

	var stream: AudioStream = await load_audio(path)
	if stream == null:
		return

	var p := _sfx_pool[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _SFX_POOL_SIZE
	
	p.stop()
	p.stream = stream
	p.volume_db = volume
	p.play()
#endregion


#region Bus Volume & Mute
## 设置某总线的线性音量 [0,1](供设置菜单调"音乐/音效音量")。总线名用 BGM/SFX/Master。
func set_bus_volume(bus: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0, 1.0)))


## 读取某总线的线性音量 [0,1]。
func get_bus_volume(bus: String) -> float:
	var idx := AudioServer.get_bus_index(bus)
	if idx == -1:
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(idx))


## 设置某总线静音状态。总线名用 BGM/SFX/Master。
func set_bus_mute(bus: String, mute: bool) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, mute)


## 获取某总线是否处于静音状态。
func is_bus_muted(bus: String) -> bool:
	var idx := AudioServer.get_bus_index(bus)
	if idx == -1:
		return false
	return AudioServer.is_bus_mute(idx)
#endregion


#region Music & SFX Switches
## 开关背景音乐（设置 BGM 总线静音状态）。
func set_music_enabled(enabled: bool) -> void:
	set_bus_mute(_BUS_BGM, not enabled)


## 背景音乐是否开启。
func is_music_enabled() -> bool:
	return not is_bus_muted(_BUS_BGM)


## 开关音效（设置 SFX 总线静音状态）。
func set_sfx_enabled(enabled: bool) -> void:
	set_bus_mute(_BUS_SFX, not enabled)


## 音效是否开启。
func is_sfx_enabled() -> bool:
	return not is_bus_muted(_BUS_SFX)
#endregion


#region Playback State Control
## 暂停/恢复全部播放器（窗口失焦用 stream_paused，不改音量）。
func set_paused(paused: bool) -> void:
	for p in _bgm_players:
		p.stream_paused = paused
	for p in _sfx_pool:
		p.stream_paused = paused
	if _sfx_player:
		_sfx_player.stream_paused = paused
#endregion


#region Asset Loading
## 异步加载音频资源（复用 App.asset 缓存）
func load_audio(path: String) -> AudioStream:
	if path.is_empty():
		return null
	
	var result := await App.asset.load(path)
	if result.is_err():
		App.log.warn("AudioService", "Audio file not found or load failed: %s" % path)
		return null
		
	return result.value as AudioStream
#endregion
#endregion

#region Internal
## kill 掉正在进行的 BGM tween(若有),让新的淡变从当前状态接管。
func _kill_bgm_tween() -> void:
	if _bgm_tween != null and _bgm_tween.is_valid():
		_bgm_tween.kill()


## 确保音频总线存在,不存在则创建并 send 到 Master(免去手工维护 default_bus_layout.tres)。
func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, _BUS_MASTER)


## 确保任何类型的音频流对象在作为 BGM 播放时均开启循环播放
static func _ensure_stream_loop(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
#endregion
