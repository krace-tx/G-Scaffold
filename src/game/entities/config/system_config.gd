class_name SystemConfig
extends Resource

## 游戏系统行为与调优配置数据实体（服务端下发）。
## 集中管理玩法闲置引导时限与远端音频音量调节参数。

#region Gameplay Tuning
@export var guide_inactivity_threshold: float = 20.0	## 拼图过程中玩家无操作时触发闲置引导提示的等待时长（秒）
#endregion

#region Audio Tuning
@export var audio_volumes_db: Dictionary = {}			## 远端音频分贝（dB）增益调节映射表（音频资源标识 → 分贝偏移）
#endregion

## JSON 字段名 → 自定义 Resource 脚本路径映射表。
const SCRIPT_PATHS := {
	"": "res://src/game/entities/config/system_config.gd",
}


#region Codec
## 将当前实体编码为 JSON 兼容的字典格式。
func encode() -> Dictionary:
	return ResourceCodecUtils.encode(self)


## 从字典数据解码还原为 [SystemConfig] 实体对象。
static func decode(encoded: Dictionary, script_paths: Dictionary = SCRIPT_PATHS) -> SystemConfig:
	return ResourceCodecUtils.decode(encoded, script_paths) as SystemConfig


## 克隆一份当前实体的独立深拷贝副本。
func clone() -> SystemConfig:
	return ResourceCodecUtils.clone(self, SCRIPT_PATHS) as SystemConfig
#endregion
