class_name SaveStage
extends BootStage

## 阶段 2b:存档加载(含版本迁移)。磁盘 I/O 失败应阻断并弹重试(见 boot-sequence.md)。

#region Public API
func get_name() -> String:
	return "Save"


func failure_strategy() -> BootFailureStrategy.Kind:
	return BootFailureStrategy.Kind.RETRY


func run(_ctx: BootContext) -> Result:
	App.save = SaveService.new()
	var res := App.save.load_or_create()
	if res.is_err():
		return res

	App.log.info(LOG_TAG, "save ready")
	return Result.ok()
#endregion
