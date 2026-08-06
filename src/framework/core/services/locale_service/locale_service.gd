class_name LocaleService
extends RefCounted

## 多语言与本地化服务。
##
## 负责管理当前语言设置、保存用户语言偏好、以及与 Godot 的 TranslationServer 交互。
## 改变语言时会发出 Bus.locale_changed 信号，以便 UI 动态刷新。

#region Constants & Enums
## 支持的语言列表，键为语言代码，值为显示名称
const SUPPORTED_LOCALES: Dictionary = {
	"zh_CN": "简体中文",
	"en": "English",
	"ar": "العربية"
}

## 默认语言代码
const DEFAULT_LOCALE: String = "ar"
#endregion

#region Exports & State
## 多语言持久化配置
var _locale_persist_item := PersistItem.new(
	"LocaleService-locale_setting",                            ## 资源 ID
	"user://framework/locale_service/locale_setting.tres",     ## 磁盘持久化路径(user://)
	"",                                                        ## 本地兜底资源(res://),无需兜底
	"", "GET",                                                 ## 拉取地址与方法,纯本地设置无需拉取
	"", "POST",                                                ## 推送地址与方法,纯本地设置无需推送
	{
		"": "res://src/framework/core/services/locale_service/locale_setting.gd"  ## 字段 → tres 声明脚本映射
	}
)
var _current_locale_setting: LocaleSetting = LocaleSetting.new(DEFAULT_LOCALE)
#endregion

func _init() -> void:
	load_locale_setting()

#region Public API
## 初始化语言设置
func load_locale_setting() -> void:
	var saved_locale_setting: LocaleSetting = null
	if App.persist:
		saved_locale_setting = App.persist.read(_locale_persist_item, PersistService.ReadMode.MEMORY_THEN_DISK)
	
	if saved_locale_setting is LocaleSetting and SUPPORTED_LOCALES.has(saved_locale_setting.locale):
		set_locale(saved_locale_setting.locale, false)
	else:
		# 自动检测系统语言，如果不支持则退化为默认语言
		var system_locale := OS.get_locale_language()
		if SUPPORTED_LOCALES.has(system_locale):
			set_locale(system_locale, false)
		else:
			set_locale(DEFAULT_LOCALE, false)


## 获取当前语言代码
func get_current_locale_setting() -> String:
	return _current_locale_setting.locale


## 设置当前语言代码
func set_locale(locale: String, save_to_disk: bool = true) -> void:
	if not SUPPORTED_LOCALES.has(locale):
		App.log.warn("LocaleService", "Unsupported locale: %s, falling back to default" % locale)
		locale = DEFAULT_LOCALE
		
	_current_locale_setting.locale = locale
	TranslationServer.set_locale(locale)
	
	if save_to_disk and App.persist:
		App.persist.write(_locale_persist_item, PersistService.WriteMode.MEMORY_AND_DISK, _current_locale_setting)
		
	App.log.info("LocaleService", "Locale changed to: %s (%s)" % [locale, SUPPORTED_LOCALES[locale]])
	Bus.locale_changed.emit(locale)


## 获取所有支持的语言
func get_supported_locales() -> Dictionary:
	return SUPPORTED_LOCALES
#endregion
