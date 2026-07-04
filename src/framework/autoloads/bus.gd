extends Node

## 全局信号总线(Autoload)。
##
## 只承载"已发生的事实"(过去式命名的领域事件),不承载"请求/命令"。
## 想让某个模块做事,调用 `App.xxx` 的方法,而不是往这里加 `*_requested` 信号。
## 完整铁律见 docs/architecture/communication.md。
##
## 按领域分组(app / scene / ui / economy / platform …),每个领域一个 #region,
## 只在对应里程碑真正落地该领域功能时才添加信号,不预先占位(YAGNI)。

#region App domain
## 应用切到后台(NOTIFICATION_APPLICATION_PAUSED)。由 [App] 转发。
signal app_paused

## 应用从后台恢复(NOTIFICATION_APPLICATION_RESUMED)。由 [App] 转发。
signal app_resumed
#endregion
