# AudioService 模块文档

> status: active | 最后更新: 2026-07-04 | 代码位置: `res://src/framework/managers/audio_service.gd`

## 职责与边界

**做什么**:统一播放 BGM 与 SFX。BGM/SFX 分组总线音量(供设置菜单分别调音乐/音效)、BGM 跨场景交叉淡入淡出、SFX 播放器池复用。挂在 App 下常驻,BGM 才能跨场景不中断。

**明确不做什么**:
- 不做音频资源管理——`AudioStream` 由调用方(或 AssetService)提供,本服务只负责播放
- 不做 3D 空间音频/定位——那用节点自带的 `AudioStreamPlayer2D/3D`
- 不做音乐编排/节拍同步——超出基础框架范围(YAGNI)

## 公开 API

```gdscript
func play_bgm(stream: AudioStream, fade := 0.6) -> void   # 交叉淡变;同曲不打断
func stop_bgm(fade := 0.6) -> void
func play_sfx(stream: AudioStream) -> void                # 轮转 SFX 池
func set_bus_volume(bus: String, linear: float) -> void   # bus: "BGM"/"SFX"/"Master",linear [0,1]
func get_bus_volume(bus: String) -> float
```

## 音频总线

`BGM`、`SFX` 两条总线在 `_ready` 里**程序化创建**并 send 到 `Master`(免去手工维护 `default_bus_layout.tres`)。音量用线性 [0,1] 存取,内部换算 dB。

## BGM 交叉淡变

两个 `AudioStreamPlayer` 轮流做"当前/淡入"角色:新曲在备用播放器上从静音淡入,旧曲同时淡出,实现真正的交叉淡变。**同一曲目正在播则直接返回不打断**——这是跨场景 BGM 连续的关键(切场景时若两边都 `play_bgm(同一曲)`,不会重启)。

**竞态处理**:每次新切换先 `kill` 掉上一段淡变 tween,并用 `tween_callback` 而非 `await` 收尾 stop——tween 被 kill 时 callback 不触发,避免快速连切时旧淡变的收尾 stop 误杀新曲。

## Bus 事件

无。

## 依赖

- 依赖:`AudioServer`(引擎);无其他框架服务依赖
- 初始化时机:`CoreServiceStage`(与 Scene/UI/Asset 一同),挂在 App 下

## 持有的数据

- `_bgm_players`(2 个)、`_sfx_pool`(8 个)、`_bgm_tween`,进程生命周期存在

## 失败策略

- 未知总线名:`set/get_bus_volume` 静默返回(不崩)
- 无需 Result:播放失败无有意义的恢复动作,交给引擎

## 测试要点

- 已无头验证(2026-07-04):总线创建、音量 set/get 往返、交叉淡变切曲后 active 播放器持有新曲、同曲不 flip(不打断)、SFX 池轮转
- 后续单测(M6):淡变时长精度、快速连切不残留播放器、真机音量曲线
