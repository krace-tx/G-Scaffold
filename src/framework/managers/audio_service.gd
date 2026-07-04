class_name AudioService
extends Node

## 音频服务:BGM/SFX 分组总线音量、BGM 跨场景交叉淡入淡出、SFX 播放器池。
##
## 全项目播声音一律走这里,不要各自 new AudioStreamPlayer——那样音量分组、
## 跨场景 BGM 连续、播放器复用全失控。见 docs/modules/audio-service.md。
##
## BGM 与 SFX 各走独立音频总线(自动创建并 send 到 Master),这样设置菜单能分别
## 调"音乐音量""音效音量"。挂在 App 下常驻,BGM 才能跨场景不中断。

#region Constants & Enums
const _BUS_MASTER: String = "Master"
const _BUS_BGM: String = "BGM"
const _BUS_SFX: String = "SFX"

const _SFX_POOL_SIZE: int = 8       ## SFX 并发播放上限,轮转复用
const _DEFAULT_FADE: float = 0.6    ## BGM 交叉淡变默认时长(秒)
const _SILENT_DB: float = -80.0     ## 视作静音的分贝值(≈线性 0)
#endregion

#region Exports & State
## 两个 BGM 播放器轮流做"当前/淡入"角色,实现真正的交叉淡变(旧的淡出同时新的淡入)。
var _bgm_players: Array[AudioStreamPlayer] = []
var _bgm_active: int = 0

## SFX 播放器池,轮转使用,超过并发数会打断最早的那个(可接受)。
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_next: int = 0

## 当前正在进行的 BGM 交叉淡变 tween。新切换前先 kill 它,避免快速连切时旧淡变
## 的收尾 stop() 误杀新曲(fire-and-forget 竞态)。
var _bgm_tween: Tween
#endregion

#region Lifecycle
func _ready() -> void:
	_ensure_bus(_BUS_BGM)
	_ensure_bus(_BUS_SFX)

	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = _BUS_BGM
		add_child(p)
		_bgm_players.append(p)

	for i in _SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = _BUS_SFX
		add_child(p)
		_sfx_pool.append(p)
#endregion

#region Public API
## 播放背景音乐,与当前曲目交叉淡变。**同一曲目正在播放则不打断**(跨场景连续的关键)。
func play_bgm(stream: AudioStream, fade: float = _DEFAULT_FADE) -> void:
	var active := _bgm_players[_bgm_active]
	if active.stream == stream and active.playing:
		return   # 已在播这首,保持不中断

	_kill_bgm_tween()
	var incoming := _bgm_players[1 - _bgm_active]
	incoming.stream = stream
	incoming.volume_db = _SILENT_DB
	incoming.play()

	# 旧的淡到静音、新的淡到 0db,并行;两段淡完后再 stop 旧播放器(callback 而非
	# await,tween 被 kill 时 callback 不触发,天然避免误杀新曲)。
	_bgm_tween = create_tween().set_parallel(true)
	_bgm_tween.tween_property(active, "volume_db", _SILENT_DB, fade)
	_bgm_tween.tween_property(incoming, "volume_db", 0.0, fade)
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


## 播放一次性音效,轮转使用 SFX 池里的播放器。
func play_sfx(stream: AudioStream) -> void:
	var p := _sfx_pool[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _SFX_POOL_SIZE
	p.stream = stream
	p.play()


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
#endregion
