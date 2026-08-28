extends Node

## 游戏业务层全局聚合根 (Autoload)。
## 集中挂载并持有游戏运行时所需的全部核心业务管理器。
## 启动时由 BootStage 阶段完成各管理器的异步数据恢复与初始化。

#region Business Managers
## 玩家偏好设置业务管理器（音频开关、振动、外链与偏好持久化）
var setting: SettingManager = SettingManager.new()

## 游戏全局配置业务管理器（远端配置拉取、版本检查与热更）
var config: ConfigManager = ConfigManager.new()

## 玩家个人档案业务管理器（关卡进度、道具持有量与档案存盘）
var profile: ProfileManager = ProfileManager.new()

## 关卡与主题相册业务管理器（关卡查询、相册收集进度、过关结算）
var level: LevelManager = LevelManager.new()

## 游戏素材资产管理器（远端素材注册、分级必下/按需、本地文件缓存与纹理加载）
var asset: AssetManager = AssetManager.new()
#endregion
