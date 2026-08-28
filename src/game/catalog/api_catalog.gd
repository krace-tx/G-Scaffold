class_name ApiCatalog

## 远端 API 路由映射表（脚手架模版）。
## 集中管理各环境的基础域名 (Base Host) 与具体业务 API 路径。

#region Base Hosts
const _HOST_LOCAL: String    = "http://127.0.0.1:8000"
const _HOST_EMULATOR: String = "http://10.0.2.2:8000"
const _HOST_DEV: String      = "https://dev-api.example.com"
const _HOST_TEST: String     = "https://test-api.example.com"
const _HOST_PROD: String     = "https://api.example.com"
#endregion

#region Endpoints
const _PATH_PIN: String           = "/api/v1/pin"
const _PATH_GAME_CONFIG: String   = "/api/v1/config"
const _PATH_EVENT_REPORT: String  = "/api/v1/event/report"
#endregion

#region Host Routing
## 当前运行环境的基础 Host 域名
static var base_host: String:
	get:
		if App != null and App.env != null:
			match App.env.current:
				EnvironmentService.Env.LOCAL:
					return _HOST_LOCAL
				EnvironmentService.Env.EMULATOR:
					return _HOST_EMULATOR
				EnvironmentService.Env.DEV:
					return _HOST_DEV
				EnvironmentService.Env.TEST:
					return _HOST_TEST
				EnvironmentService.Env.PROD:
					return _HOST_PROD
		return _HOST_DEV
#endregion

#region Endpoints URLs
static var PIN: String:
	get:
		return base_host + _PATH_PIN

static var GAME_CONFIG: String:
	get:
		return base_host + _PATH_GAME_CONFIG

static var EVENT_REPORT: String:
	get:
		return base_host + _PATH_EVENT_REPORT
#endregion
