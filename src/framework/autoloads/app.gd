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
## `log` 与内置全局函数 log()(自然对数)同名,此处刻意遮蔽:
## `App.log` 这个命名在全项目统一且更常用,不会被误认成数学函数。
@warning_ignore("shadowed_global_identifier")
var log: LogService   ## M0:由 Bootstrap 阶段 1 最先创建

var scenes: SceneService   ## M1:由 Bootstrap 创建并挂到 App 下(见 bootstrap.gd)
var ui: UIService          ## M1:由 Bootstrap 创建并挂到 App 下

var time: TimeService      ## M2:权威时间源(未校时前不可信)
var config: ConfigService  ## M2:三层合并配置(remote > local > defaults)
var save: SaveService      ## M2:版本化 JSON 存档

var platform: PlatformService  ## M3:平台能力门面(App.platform.ads / .analytics)
#endregion

#region Lifecycle
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			_on_app_paused()
		NOTIFICATION_APPLICATION_RESUMED:
			_on_app_resumed()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_on_go_back()
#endregion

#region Internal
func _on_app_paused() -> void:
	if log: log.info("app", "application paused")
	# 切后台是 iOS 上唯一可靠的保存时机,务必 flush 存档。
	if save: save.flush()
	Bus.app_paused.emit()


func _on_app_resumed() -> void:
	if log: log.info("app", "application resumed")
	# TODO(M4): 重连、刷新远程配置、校时。
	Bus.app_resumed.emit()


## Android 返回键:先给 UI 栈处理(关栈顶弹窗);UI 没消费再走场景级返回。
func _on_go_back() -> void:
	if ui and ui.handle_back():
		return
	# TODO(后续):无弹窗时的场景级返回 / 主菜单退出确认(见 boot-sequence.md)。
	if log: log.info("app", "back not consumed by ui — scene-level back is TODO")
#endregion
