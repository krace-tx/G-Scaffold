class_name BaseUI
extends Control

## 所有由 UIService 管理的界面 / 弹窗的根节点契约。
##
## UIService 打开 / 关闭界面时会调用这三个钩子。界面预制体(.tscn)的根节点脚本
## 都应 extends BaseUI,并在 ui_registry.tres 里登记(层级 + 缓存策略)。
## 完整用法见 docs/guides/add-a-ui.md、docs/modules/ui-service.md。

#region Public API
## 打开钩子:实例入树后调用,[param _params] 为 open() 透传的参数。
## 默认空实现,子类按需覆写(可含 await,但 open() 不会等待其完成)。
func _on_open(_params: Dictionary) -> void:
	pass


## 关闭钩子:界面即将从层里移除前调用。**必须在这里断开所有对外信号连接**,
## 否则 KEEP 缓存的界面复用时会重复响应。默认空实现,子类按需覆写。
func _on_close() -> void:
	pass


## 返回键钩子(Android 返回 / ui_cancel)。返回 true = 本界面已自行消费(如弹出
## "放弃修改?"确认框),UIService 不再关闭它;返回 false = 未消费,UIService 走
## 默认行为把它关掉。默认返回 false。
func _on_back() -> bool:
	return false
#endregion
