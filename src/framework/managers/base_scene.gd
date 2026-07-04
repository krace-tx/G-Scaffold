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

#region Public API
## 进场钩子,[param _params] 为 SceneService.replace() 透传的参数。
## 默认空实现,子类按需覆写并可 await。
func _on_enter(_params: Dictionary) -> void:
	pass


## 退场钩子,场景即将被替换前调用。默认空实现,子类按需覆写并可 await。
func _on_exit() -> void:
	pass
#endregion
