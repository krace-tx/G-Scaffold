class_name BaseScene
extends Node

## 顶层场景根节点的生命周期契约。
##
## SceneService 是全项目唯一允许调用 change_scene 系 API 的地方,场景切换时
## 会依次调用旧场景的 [method _on_exit] 和新场景的 [method _on_enter]。
## 场景根节点(不论 Control / Node2D / Node3D)的脚本都应 extends BaseScene。
##
## 两个钩子都可以 await(播放入场演出、保存进度等),但 [method _on_enter]
## 有 10 秒超时保护(见 docs/modules/scene-service.md 失败策略):超时后
## SceneService 会强制揭开遮罩继续,场景自身仍会跑完,只是玩家不再等待。
## 详见 docs/architecture/boot-sequence.md、docs/modules/scene-service.md。
##
## [b]栈式切换支持 (push/pop)[/b][br]
## 支持栈式切换(push/pop:压入战斗/小游戏子场景、返回时恢复原场景),
## 伴随 [method _on_suspend] 和 [method _on_resume]。
## 详见 docs/architecture/boot-sequence.md、docs/modules/scene-service.md。

#region Public API
## 进场钩子:场景实例化并入树后、遮罩揭开前调用。[param _params] 为
## SceneService.replace() 透传的参数。默认空实现,子类按需覆写并可 await。
func _on_enter(_params: Dictionary) -> void:
	pass


## 挂起钩子:被上层场景压住、暂停但保活时调用。默认空实现,子类按需覆写并可 await。
func _on_suspend() -> void:
	pass


## 恢复钩子:上层 pop 后恢复到前台时调用。默认空实现,子类按需覆写并可 await。
## [param _params] 可带回传结果。
func _on_resume(_params: Dictionary) -> void:
	pass


## 退场钩子:场景[b]真正销毁前[/b]调用(而非"离开前台")。默认空实现,
## 子类按需覆写并可 await。
##
## 语义严格限定为"销毁前"——将来若引入栈式切换,"被压住但保活"会是另一个
## 独立钩子 _on_suspend,不会复用本方法。所以"保存进度"这类逻辑放这里是安全的:
## 它只在场景确实要消失时触发,不会在被临时挂起时误触发。
func _on_exit() -> void:
	pass
	

#endregion
