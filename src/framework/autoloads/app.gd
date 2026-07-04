extends Node

## 全局服务聚合根(Autoload)。
##
## 持有全部框架服务的类型化引用(`App.log`、`App.scenes`……),由 [Bootstrap]
## 按阶段顺序创建并赋值,不依赖 Autoload 加载顺序。全项目只有 [App] 与 [Bus]
## 两个 Autoload,禁止新增,详见 docs/architecture/decisions/0001-typed-app-root.md。
##
## 字段随里程碑逐个补充:一个服务类还不存在时,不能声明它的类型化字段
## (GDScript 无法引用不存在的类),所以本文件只在服务落地那个里程碑里追加对应行。
##
## 同时接管应用生命周期通知(切后台/恢复/返回键),转发为 [Bus] 领域事件。
## 详见 docs/architecture/boot-sequence.md 应用生命周期一节。

#region Exports & State
var log: LogService   ## M0:由 Bootstrap 阶段 1 最先创建
#endregion

#region Lifecycle
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			_on_app_paused()
		NOTIFICATION_APPLICATION_RESUMED:
			_on_app_resumed()
#endregion

#region Internal
func _on_app_paused() -> void:
	if log: log.info("app", "application paused")
	# TODO(M2): App.save.flush() —— iOS 上唯一可靠的保存时机。
	Bus.app_paused.emit()


func _on_app_resumed() -> void:
	if log: log.info("app", "application resumed")
	# TODO(M4): 重连、刷新远程配置、校时。
	Bus.app_resumed.emit()
#endregion
