class_name ShareClient
extends RefCounted

## 系统分享子系统统一入口门面 (Platform.share)。
## 封装原生系统分享与跨平台 Mock 兜底，支持纯文本、本地图片、Texture 纹理与屏幕截屏分享。

signal share_completed(activity_type: String)
signal share_failed(error_message: String)
signal share_canceled()

var _adapter = null


#region Lifecycle
func initialize() -> Result:
	if App.env.is_mobile():
		_adapter = NativeShareAdapter.new()
	else:
		_adapter = MockShareAdapter.new()

	_adapter.share_completed.connect(func(type: String): share_completed.emit(type))
	_adapter.share_failed.connect(func(msg: String): share_failed.emit(msg))
	_adapter.share_canceled.connect(func(): share_canceled.emit())

	var res: Result = _adapter.initialize()
	App.log.info("ShareClient", "Share subsystem initialized")
	return res
#endregion


#region Public API
## 分享纯文本。
func share_text(title: String, subject: String, content: String) -> void:
	if _adapter != null:
		_adapter.share_text(title, subject, content)


## 分享图片文件（支持 res:// 或 user:// 路径）。
func share_image_file(file_path: String, title: String, subject: String, content: String) -> void:
	if _adapter != null:
		_adapter.share_image_file(file_path, title, subject, content)


## 分享 Texture2D 纹理对象。
func share_texture(texture: Texture2D, title: String, subject: String, content: String) -> void:
	if _adapter != null:
		_adapter.share_texture(texture, title, subject, content)


## 分享游戏当前视口屏幕截图。[param flip_y] 在特定平台截图垂直倒置时置为 true。
func share_screenshot(title: String, subject: String, content: String, flip_y: bool = false) -> void:
	if _adapter != null:
		_adapter.share_screenshot(title, subject, content, flip_y)
#endregion
