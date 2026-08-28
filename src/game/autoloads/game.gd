extends Node

## 游戏业务层聚合根 (Autoload / Service Locator)
## 仅持有通用基础业务管理器：设置、配置、用户档案。

var setting: SettingManager
var config: ConfigManager
var profile: ProfileManager

func _ready() -> void:
	setting = SettingManager.new()
	config = ConfigManager.new()
	profile = ProfileManager.new()
