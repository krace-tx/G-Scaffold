class_name Bootstrap
extends Node

## 启动入口:挂在 [code]game/scenes/boot.tscn[/code] 根节点,委托 [BootPipeline] 跑各阶段。
##
## 阶段列表、失败策略与执行细节见 [code]core/boot/[/code] 与
## [code]docs/architecture/boot-sequence.md[/code]。

#region Lifecycle
func _ready() -> void:
	await _run()
#endregion

#region Internal
## 构造默认 Pipeline 并阻塞到全部 Stage 完成或失败终止。
func _run() -> void:
	var pipeline := BootPipeline.new(self, BootPipeline.default_stages())
	await pipeline.run()
#endregion
