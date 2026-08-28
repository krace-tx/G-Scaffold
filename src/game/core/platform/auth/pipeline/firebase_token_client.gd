class_name FirebaseTokenClient
extends RefCounted

## Firebase REST API 换 Token 服务。
## 将各平台 OAuth Token（Google id_token / Apple identity_token）兑换为 Firebase 用户凭据。


func exchange_token(provider_id: String, id_token: String) -> Result:
	var post_body := "id_token=%s&providerId=%s" % [id_token, provider_id]
	var payload := {
		"postBody": post_body,
		"requestUri": "http://localhost",
		"returnSecureToken": true,
	}

	var url := PlatformCatalog.FIREBASE_AUTH_URL + PlatformCatalog.FIREBASE_WEB_API_KEY
	var res: Result = await App.net.post_request(url, payload)

	if res.is_ok() and res.value is Dictionary:
		return Result.ok(res.value as Dictionary)

	var err_msg := "Firebase auth failed"
	if res.is_err():
		if res.error is Dictionary:
			err_msg = str((res.error as Dictionary).get("message", err_msg))
		else:
			err_msg = str(res.error)

	return Result.err(err_msg)
