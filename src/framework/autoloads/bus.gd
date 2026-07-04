extends Node

## 全局信号总线(Autoload)。
##
## 只承载"已发生的事实"(过去式命名的领域事件),不承载"请求/命令"。
## 想让某个模块做事,调用 `App.xxx` 的方法,而不是往这里加 `*_requested` 信号。
## 完整铁律见 docs/architecture/communication.md。
##
## 按领域分组(app / scene / ui / economy / platform …),每个领域一个 #region,
## 只在对应里程碑真正落地该领域功能时才添加信号,不预先占位(YAGNI)。
##
## 全文件关掉 unused_signal 警告:Bus 的信号**按设计**都在别的文件里 emit/connect
## (发出者与接收者解耦),bus.gd 内部一次都不 emit,静态分析据此误报"未使用"。
## 只在本文件抑制,其他地方(如实体脚本声明却没 emit 的信号)仍然照常告警。
@warning_ignore_start("unused_signal")

#region App domain
## 应用切到后台(NOTIFICATION_APPLICATION_PAUSED)。由 [App] 转发。
signal app_paused

## 应用从后台恢复(NOTIFICATION_APPLICATION_RESUMED)。由 [App] 转发。
signal app_resumed
#endregion

#region Scene domain
## 顶层场景切换完成(新场景 _on_enter 已跑完)。由 [SceneService] 发出。
signal scene_changed(scene_id: StringName)

## 顶层场景切换失败(id 不存在 / 加载失败)。由 [SceneService] 发出。
signal scene_change_failed(scene_id: StringName)
#endregion

#region UI domain
## 界面已打开(实例入树、_on_open 已调用)。由 [UIService] 发出。
signal ui_opened(ui_id: StringName)

## 界面已关闭(_on_close 已调用、已从层里移除)。由 [UIService] 发出。
signal ui_closed(ui_id: StringName)
#endregion

#region Platform domain
## 激励视频看完、应发奖。由**业务代码**在拿到 [method AdResult.is_rewarded] 为真时发出
## ([PlatformService] 只返回结果,不替业务决定发奖)。[param placement] 为广告位标识。
signal ad_reward_granted(placement: StringName)
#endregion
