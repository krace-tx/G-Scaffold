class_name EnvironmentService
extends RefCounted

## API 环境枚举
enum GameEnvironment {
	LOCAL,
	DEV,
	PROD
}

## 当前环境，默认设置为 DEV
var current_env: GameEnvironment = GameEnvironment.DEV

func _init() -> void:
	_detect_environment()

## 自动识别环境类型
func _detect_environment() -> void:
	if OS.has_feature("prod"):
		current_env = GameEnvironment.PROD
	elif OS.has_feature("local"):
		current_env = GameEnvironment.LOCAL
	else:
		# 兜底与默认环境
		current_env = GameEnvironment.DEV

# --- 便捷判断方法 ---

## 是否为生产环境
func is_prod() -> bool:
	return current_env == GameEnvironment.PROD

## 是否为开发环境
func is_dev() -> bool:
	return current_env == GameEnvironment.DEV

## 是否为本地环境
func is_local() -> bool:
	return current_env == GameEnvironment.LOCAL

## 获取环境名称字符串（常用于日志打印）
func get_env_name() -> String:
	return GameEnvironment.keys()[current_env]
