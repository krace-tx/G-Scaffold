class_name NativeShareAdapter
extends RefCounted

## 系统原生分享适配器。
## 封装与 Android / iOS 系统分享面板的原生桥接。

signal share_completed(activity_type: String)
signal share_failed(error_message: String)
signal share_canceled()

var _share_node: Share = null


func initialize() -> Result:
	_share_node = Share.new()
	NodeUtils.mount_required(_share_node, Platform, "NativeShareNode")
	_share_node.share_completed.connect(func(type: String): share_completed.emit(type))
	_share_node.share_failed.connect(func(msg: String): share_failed.emit(msg))
	_share_node.share_canceled.connect(func(): share_canceled.emit())
	App.log.info("NativeShareAdapter", "Native share adapter initialized")
	return Result.ok()


func share_text(title: String, subject: String, content: String) -> void:
	_share_node.share_text(title, subject, content)


func share_image_file(file_path: String, title: String, subject: String, content: String) -> void:
	var global_path := ProjectSettings.globalize_path(file_path)
	_share_node.share_image(global_path, title, subject, content)


func share_texture(texture: Texture2D, title: String, subject: String, content: String) -> void:
	_share_node.share_texture(texture, title, subject, content)


func share_screenshot(title: String, subject: String, content: String, flip_y: bool = false) -> void:
	_share_node.share_viewport(App.get_viewport(), title, subject, content, flip_y)
