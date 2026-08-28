class_name MockShareAdapter
extends RefCounted

## Mock 分享适配器。
## 在 PC / 编辑器环境下打印日志并模拟异步分享成功回调。

signal share_completed(activity_type: String)
@warning_ignore("unused_signal")
signal share_failed(error_message: String)
@warning_ignore("unused_signal")
signal share_canceled()


func initialize() -> Result:
	App.log.info("MockShareAdapter", "Mock share adapter initialized")
	return Result.ok()


func share_text(title: String, _subject: String, content: String) -> void:
	_mock_share("text: title='%s', content='%s'" % [title, content])


func share_image_file(file_path: String, title: String, _subject: String, _content: String) -> void:
	_mock_share("image_file: path='%s', title='%s'" % [file_path, title])


func share_texture(texture: Texture2D, title: String, _subject: String, _content: String) -> void:
	_mock_share("texture: path='%s', title='%s'" % [texture.resource_path if texture else "null", title])


func share_screenshot(title: String, _subject: String, _content: String, _flip_y: bool = false) -> void:
	_mock_share("screenshot: title='%s'" % title)


func _mock_share(desc: String) -> void:
	App.log.info("MockShareAdapter", "[Mock] share %s" % desc)
	(func() -> void:
		await App.get_tree().create_timer(0.3).timeout
		share_completed.emit("MockActivity")
	).call()
